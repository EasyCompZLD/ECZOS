// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 EasyComp Zeeland

#include <QApplication>
#include <QCloseEvent>
#include <QCommandLineParser>
#include <QDesktopServices>
#include <QDialogButtonBox>
#include <QFile>
#include <QHBoxLayout>
#include <QIcon>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLabel>
#include <QLineEdit>
#include <QMainWindow>
#include <QMap>
#include <QMessageBox>
#include <QPushButton>
#include <QQmlEngine>
#include <QScrollArea>
#include <QSplitter>
#include <QStandardPaths>
#include <QSet>
#include <QTreeWidget>
#include <QTreeWidgetItemIterator>
#include <QUrl>
#include <QVBoxLayout>

#include <KAuth/Action>
#include <KAuth/ExecuteJob>
#include <KAuthorized>
#include <KCModule>
#include <KCModuleLoader>
#include <KJob>
#include <KPluginMetaData>

#include <algorithm>
#include <initializer_list>
#include <memory>

namespace {

QString categoryFor(const KPluginMetaData &data)
{
    const QString id = data.pluginId().toLower();
    const QString file = data.fileName().toLower();
    const auto containsAny = [&id](std::initializer_list<const char *> words) {
        for (const char *word : words) {
            if (id.contains(QLatin1String(word))) {
                return true;
            }
        }
        return false;
    };
    if (file.contains(QStringLiteral("/kinfocenter/"))) {
        return QStringLiteral("Systeeminformatie");
    }
    if (containsAny({"lookandfeel", "style", "color", "icon", "cursor", "font", "splash", "wallpaper", "decoration", "theme"})) {
        return QStringLiteral("Uiterlijk");
    }
    if (containsAny({"network", "proxy", "firewall", "bluetooth", "bolt", "samba", "webshortcut", "kdeconnect"})) {
        return QStringLiteral("Netwerk en verbindingen");
    }
    if (containsAny({"audio", "sound", "mouse", "keyboard", "touch", "screen", "display", "power", "energy", "printer", "tablet", "controller", "kamera", "automount"})) {
        return QStringLiteral("Apparaten en energie");
    }
    if (containsAny({"region", "language", "spell", "user", "clock", "time", "date", "account"})) {
        return QStringLiteral("Taal, tijd en accounts");
    }
    if (containsAny({"locker", "wallet", "permission", "privacy", "feedback", "security", "recent"})) {
        return QStringLiteral("Privacy en beveiliging");
    }
    return QStringLiteral("Werkruimte en gedrag");
}

QList<KPluginMetaData> availableModules()
{
    QList<KPluginMetaData> modules;
    QSet<QString> seen;
    const auto filter = [](const KPluginMetaData &data) {
        if (data.isHidden() || !KAuthorized::authorizeControlModule(data.pluginId())) {
            return false;
        }
        const QStringList platforms = data.value(QStringLiteral("X-KDE-OnlyShowOnQtPlatforms"), QStringList());
        if (!platforms.isEmpty()) {
            bool supported = false;
            for (const QString &platform : platforms) {
                supported |= qApp->platformName().startsWith(platform);
            }
            if (!supported) {
                return false;
            }
        }
        const QStringList formFactors = data.formFactors();
        return formFactors.isEmpty() || formFactors.contains(QStringLiteral("all")) || formFactors.contains(QStringLiteral("desktop"));
    };
    const QStringList namespaces = {
        QStringLiteral("plasma/kcms"),
        QStringLiteral("plasma/kcms/systemsettings"),
        QStringLiteral("plasma/kcms/systemsettings_qwidgets"),
        QStringLiteral("plasma/kcms/kinfocenter"),
    };
    for (const QString &nameSpace : namespaces) {
        for (const KPluginMetaData &data : KPluginMetaData::findPlugins(nameSpace, filter)) {
            if (!seen.contains(data.pluginId())) {
                seen.insert(data.pluginId());
                modules.append(data);
            }
        }
    }
    std::sort(modules.begin(), modules.end(), [](const KPluginMetaData &left, const KPluginMetaData &right) {
        const QString leftCategory = categoryFor(left);
        const QString rightCategory = categoryFor(right);
        if (leftCategory != rightCategory) {
            return leftCategory.localeAwareCompare(rightCategory) < 0;
        }
        return left.name().localeAwareCompare(right.name()) < 0;
    });
    return modules;
}

QJsonDocument moduleInventory(const QList<KPluginMetaData> &modules)
{
    QJsonArray records;
    for (const KPluginMetaData &data : modules) {
        records.append(QJsonObject{
            {QStringLiteral("id"), data.pluginId()},
            {QStringLiteral("name"), data.name()},
            {QStringLiteral("description"), data.description()},
            {QStringLiteral("category"), categoryFor(data)},
        });
    }
    return QJsonDocument(QJsonObject{{QStringLiteral("schemaVersion"), 1}, {QStringLiteral("modules"), records}});
}

class SettingsWindow final : public QMainWindow
{
    Q_OBJECT

public:
    explicit SettingsWindow(const QList<KPluginMetaData> &modules)
        : m_modules(modules)
        , m_engine(std::make_shared<QQmlEngine>())
    {
        setWindowTitle(QStringLiteral("ECZOS Instellingen"));
        setWindowIcon(QIcon::fromTheme(QStringLiteral("preferences-system")));
        resize(1180, 760);
        setMinimumSize(920, 620);

        auto *central = new QWidget(this);
        auto *outer = new QHBoxLayout(central);
        outer->setContentsMargins(0, 0, 0, 0);
        outer->setSpacing(0);
        setCentralWidget(central);

        auto *sidebar = new QWidget(central);
        sidebar->setObjectName(QStringLiteral("sidebar"));
        sidebar->setFixedWidth(310);
        auto *sideLayout = new QVBoxLayout(sidebar);
        sideLayout->setContentsMargins(18, 18, 18, 18);
        sideLayout->setSpacing(10);

        auto *logo = new QLabel(sidebar);
        QPixmap logoPixmap(QStringLiteral("/usr/share/eczos/branding/logo/logo.png"));
        logo->setPixmap(logoPixmap.scaled(190, 74, Qt::KeepAspectRatio, Qt::SmoothTransformation));
        logo->setAlignment(Qt::AlignCenter);
        sideLayout->addWidget(logo);

        m_search = new QLineEdit(sidebar);
        m_search->setPlaceholderText(QStringLiteral("Zoek in alle instellingen…"));
        m_search->setClearButtonEnabled(true);
        sideLayout->addWidget(m_search);

        m_tree = new QTreeWidget(sidebar);
        m_tree->setHeaderHidden(true);
        m_tree->setRootIsDecorated(true);
        m_tree->setIndentation(15);
        m_tree->setAnimated(true);
        sideLayout->addWidget(m_tree, 1);

        auto *identity = new QLabel(QStringLiteral("EasyComp Zeeland\nOperating System"), sidebar);
        identity->setObjectName(QStringLiteral("identity"));
        sideLayout->addWidget(identity);
        outer->addWidget(sidebar);

        m_content = new QWidget(central);
        m_contentLayout = new QVBoxLayout(m_content);
        m_contentLayout->setContentsMargins(22, 18, 22, 16);
        m_contentLayout->setSpacing(12);
        m_heading = new QLabel(QStringLiteral("Systeemvoorkeuren"), m_content);
        m_heading->setObjectName(QStringLiteral("pageHeading"));
        m_description = new QLabel(QStringLiteral("Kies links een onderdeel. Alle instellingen blijven in dit venster."), m_content);
        m_description->setObjectName(QStringLiteral("pageDescription"));
        m_description->setWordWrap(true);
        m_contentLayout->addWidget(m_heading);
        m_contentLayout->addWidget(m_description);

        m_moduleArea = new QScrollArea(m_content);
        m_moduleArea->setWidgetResizable(true);
        m_moduleArea->setFrameShape(QFrame::NoFrame);
        m_contentLayout->addWidget(m_moduleArea, 1);

        m_buttons = new QDialogButtonBox(m_content);
        m_apply = m_buttons->addButton(QStringLiteral("Opslaan"), QDialogButtonBox::ApplyRole);
        m_reset = m_buttons->addButton(QStringLiteral("Wijzigingen ongedaan maken"), QDialogButtonBox::ResetRole);
        m_defaults = m_buttons->addButton(QStringLiteral("Standaardinstellingen"), QDialogButtonBox::ResetRole);
        m_help = m_buttons->addButton(QStringLiteral("Hulp"), QDialogButtonBox::HelpRole);
        m_contentLayout->addWidget(m_buttons);
        outer->addWidget(m_content, 1);

        setStyleSheet(QStringLiteral(R"(
            #sidebar { background: #0b1926; border-right: 1px solid #152c3e; }
            #sidebar QLineEdit { min-height: 38px; padding: 0 11px; color: #f4f8fb; background: #172a3b; border: 1px solid #294156; border-radius: 9px; }
            #sidebar QTreeWidget { color: #eaf3f8; background: transparent; border: 0; outline: 0; }
            #sidebar QTreeWidget::item { min-height: 34px; padding: 2px 6px; border-radius: 7px; }
            #sidebar QTreeWidget::item:selected { background: #183b52; color: #ffffff; }
            #sidebar QTreeWidget::item:hover { background: #132b3d; }
            #identity { color: #6f8da2; font-size: 11px; }
            #pageHeading { font-size: 25px; font-weight: 700; }
            #pageDescription { color: palette(mid); font-size: 13px; }
        )"));

        populateTree();
        showLandingPage();
        connect(m_search, &QLineEdit::textChanged, this, &SettingsWindow::filterTree);
        connect(m_tree, &QTreeWidget::itemActivated, this, &SettingsWindow::activateItem);
        connect(m_tree, &QTreeWidget::itemClicked, this, &SettingsWindow::activateItem);
        connect(m_apply, &QPushButton::clicked, this, &SettingsWindow::saveModule);
        connect(m_reset, &QPushButton::clicked, this, [this] {
            if (m_module) {
                m_module->load();
            }
        });
        connect(m_defaults, &QPushButton::clicked, this, [this] {
            if (m_module) {
                m_module->defaults();
            }
        });
        connect(m_help, &QPushButton::clicked, this, [this] {
            if (!m_module) {
                return;
            }
            const QString path = m_module->metaData().value(QStringLiteral("X-DocPath"));
            if (!path.isEmpty()) {
                QDesktopServices::openUrl(QUrl(QStringLiteral("help:/") + path));
            }
        });
        updateButtons();
    }

    bool openModule(const QString &id)
    {
        if (!m_byId.contains(id)) {
            return false;
        }
        for (QTreeWidgetItemIterator it(m_tree); *it; ++it) {
            if ((*it)->data(0, Qt::UserRole).toString() == id) {
                m_tree->setCurrentItem(*it);
                loadModule(id);
                return true;
            }
        }
        return false;
    }

protected:
    void closeEvent(QCloseEvent *event) override
    {
        if (resolveChanges()) {
            event->accept();
        } else {
            event->ignore();
        }
    }

private:
    void populateTree()
    {
        QMap<QString, QTreeWidgetItem *> categories;
        for (const KPluginMetaData &data : m_modules) {
            m_byId.insert(data.pluginId(), data);
            const QString category = categoryFor(data);
            if (!categories.contains(category)) {
                auto *categoryItem = new QTreeWidgetItem(m_tree, QStringList(category));
                categoryItem->setFlags(Qt::ItemIsEnabled);
                categoryItem->setExpanded(true);
                categories.insert(category, categoryItem);
            }
            auto *item = new QTreeWidgetItem(categories.value(category), QStringList(data.name()));
            item->setToolTip(0, data.description());
            item->setData(0, Qt::UserRole, data.pluginId());
            item->setIcon(0, QIcon::fromTheme(data.iconName()));
        }
    }

    void filterTree(const QString &text)
    {
        const QString query = text.trimmed();
        for (int groupIndex = 0; groupIndex < m_tree->topLevelItemCount(); ++groupIndex) {
            QTreeWidgetItem *group = m_tree->topLevelItem(groupIndex);
            bool anyVisible = false;
            for (int childIndex = 0; childIndex < group->childCount(); ++childIndex) {
                QTreeWidgetItem *item = group->child(childIndex);
                const QString id = item->data(0, Qt::UserRole).toString();
                const KPluginMetaData data = m_byId.value(id);
                const bool visible = query.isEmpty() || item->text(0).contains(query, Qt::CaseInsensitive)
                    || data.description().contains(query, Qt::CaseInsensitive)
                    || id.contains(query, Qt::CaseInsensitive);
                item->setHidden(!visible);
                anyVisible |= visible;
            }
            group->setHidden(!anyVisible);
            if (!query.isEmpty()) {
                group->setExpanded(true);
            }
        }
    }

    void activateItem(QTreeWidgetItem *item)
    {
        const QString id = item->data(0, Qt::UserRole).toString();
        if (!id.isEmpty()) {
            loadModule(id);
        }
    }

    void showLandingPage()
    {
        auto *landing = new QWidget;
        auto *layout = new QVBoxLayout(landing);
        auto *intro = new QLabel(QStringLiteral("Alle %1 geïnstalleerde systeemonderdelen zijn vanuit de zijbalk bereikbaar.").arg(m_modules.size()), landing);
        intro->setWordWrap(true);
        intro->setStyleSheet(QStringLiteral("font-size: 18px; font-weight: 600; margin: 12px;"));
        layout->addWidget(intro);
        auto *images = new QHBoxLayout;
        const QList<QPair<QString, QString>> cards = {
            {QStringLiteral("Uiterlijk"), QStringLiteral("system-appearance.png")},
            {QStringLiteral("Beeldschermen"), QStringLiteral("system-display.png")},
            {QStringLiteral("Netwerk"), QStringLiteral("system-network.png")},
        };
        for (const auto &[title, file] : cards) {
            auto *column = new QVBoxLayout;
            auto *image = new QLabel(landing);
            const QPixmap pixmap(QStringLiteral("/usr/share/eczos/branding/screenshots/") + file);
            image->setPixmap(pixmap.scaled(260, 185, Qt::KeepAspectRatioByExpanding, Qt::SmoothTransformation));
            image->setMinimumSize(220, 160);
            image->setAlignment(Qt::AlignCenter);
            auto *caption = new QLabel(title, landing);
            caption->setAlignment(Qt::AlignCenter);
            caption->setStyleSheet(QStringLiteral("font-weight: 600;"));
            column->addWidget(image);
            column->addWidget(caption);
            images->addLayout(column, 1);
        }
        layout->addLayout(images);
        layout->addStretch(1);
        m_moduleArea->setWidget(landing);
    }

    bool resolveChanges()
    {
        if (!m_module || !m_module->needsSave()) {
            return true;
        }
        const QMessageBox::StandardButton answer = QMessageBox::warning(
            this,
            QStringLiteral("Wijzigingen opslaan?"),
            QStringLiteral("Dit onderdeel bevat wijzigingen die nog niet zijn opgeslagen."),
            QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel,
            QMessageBox::Save);
        if (answer == QMessageBox::Cancel) {
            return false;
        }
        if (answer == QMessageBox::Save) {
            saveModule();
        } else {
            m_module->load();
        }
        return true;
    }

    void loadModule(const QString &id)
    {
        if (m_module && m_module->metaData().pluginId() == id) {
            return;
        }
        if (!resolveChanges()) {
            return;
        }
        if (m_module) {
            QWidget *oldWidget = m_moduleArea->takeWidget();
            delete m_module;
            m_module = nullptr;
            delete oldWidget;
        }
        const KPluginMetaData data = m_byId.value(id);
        auto *wrapper = new QWidget;
        auto *layout = new QVBoxLayout(wrapper);
        layout->setContentsMargins(0, 0, 0, 0);
        auto *scroll = new QScrollArea(wrapper);
        scroll->setWidgetResizable(true);
        scroll->setFrameShape(QFrame::NoFrame);
        layout->addWidget(scroll);
        m_module = KCModuleLoader::loadModule(data, scroll, {}, m_engine);
        scroll->setWidget(m_module->widget());
        m_module->load();
        m_moduleArea->setWidget(wrapper);
        m_heading->setText(data.name());
        m_description->setText(data.description());
        connect(m_module, &KCModule::needsSaveChanged, this, &SettingsWindow::updateButtons);
        connect(m_module, &KCModule::buttonsChanged, this, &SettingsWindow::updateButtons);
        connect(m_module, &KCModule::representsDefaultsChanged, this, &SettingsWindow::updateButtons);
        updateButtons();
    }

    void saveModule()
    {
        if (!m_module) {
            return;
        }
        const QString actionName = m_module->authActionName();
        if (actionName.isEmpty()) {
            m_module->save();
            return;
        }
        KAuth::Action action(actionName);
        auto *job = action.execute(KAuth::Action::AuthorizeOnlyMode);
        connect(job, &KJob::result, this, [this, job] {
            if (!job->error() && m_module) {
                m_module->save();
            }
        });
        job->start();
    }

    void updateButtons()
    {
        if (!m_module) {
            m_buttons->hide();
            return;
        }
        m_buttons->show();
        const KCModule::Buttons buttons = m_module->buttons();
        m_apply->setVisible(buttons.testFlag(KCModule::Apply));
        m_apply->setEnabled(m_module->needsSave());
        m_reset->setVisible(buttons.testFlag(KCModule::Apply));
        m_reset->setEnabled(m_module->needsSave());
        m_defaults->setVisible(buttons.testFlag(KCModule::Default));
        m_defaults->setEnabled(!m_module->representsDefaults());
        const QString docPath = m_module->metaData().value(QStringLiteral("X-DocPath"));
        m_help->setVisible(buttons.testFlag(KCModule::Help) && !docPath.isEmpty());
    }

    QList<KPluginMetaData> m_modules;
    QMap<QString, KPluginMetaData> m_byId;
    std::shared_ptr<QQmlEngine> m_engine;
    QLineEdit *m_search = nullptr;
    QTreeWidget *m_tree = nullptr;
    QWidget *m_content = nullptr;
    QVBoxLayout *m_contentLayout = nullptr;
    QLabel *m_heading = nullptr;
    QLabel *m_description = nullptr;
    QScrollArea *m_moduleArea = nullptr;
    QDialogButtonBox *m_buttons = nullptr;
    QPushButton *m_apply = nullptr;
    QPushButton *m_reset = nullptr;
    QPushButton *m_defaults = nullptr;
    QPushButton *m_help = nullptr;
    KCModule *m_module = nullptr;
};

} // namespace

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    QApplication::setApplicationName(QStringLiteral("ECZOS Instellingen"));
    QApplication::setOrganizationName(QStringLiteral("EasyComp Zeeland"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Geïntegreerde systeemvoorkeuren voor ECZOS"));
    parser.addHelpOption();
    QCommandLineOption listOption(QStringLiteral("list-json"), QStringLiteral("Toon alle ingesloten modules als JSON"));
    QCommandLineOption moduleOption(QStringLiteral("module"), QStringLiteral("Open direct een instellingenonderdeel"), QStringLiteral("id"));
    parser.addOption(listOption);
    parser.addOption(moduleOption);
    parser.process(app);

    const QList<KPluginMetaData> modules = availableModules();
    if (parser.isSet(listOption)) {
        QFile output;
        output.open(stdout, QIODevice::WriteOnly);
        output.write(moduleInventory(modules).toJson(QJsonDocument::Compact));
        output.write("\n");
        return 0;
    }

    SettingsWindow window(modules);
    if (parser.isSet(moduleOption) && !window.openModule(parser.value(moduleOption))) {
        return 2;
    }
    window.show();
    return app.exec();
}

#include "main.moc"
