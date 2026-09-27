// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 EasyComp Zeeland

#include <QApplication>
#include <QAbstractButton>
#include <QButtonGroup>
#include <QClipboard>
#include <QCloseEvent>
#include <QComboBox>
#include <QCheckBox>
#include <QCommandLineParser>
#include <QDesktopServices>
#include <QDialog>
#include <QDialogButtonBox>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileDialog>
#include <QFileInfo>
#include <QFormLayout>
#include <QGridLayout>
#include <QGroupBox>
#include <QHBoxLayout>
#include <QIcon>
#include <QInputDialog>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QLabel>
#include <QLineEdit>
#include <QLocalServer>
#include <QLocalSocket>
#include <QMainWindow>
#include <QMap>
#include <QMessageBox>
#include <QPainter>
#include <QProcess>
#include <QProgressBar>
#include <QPointer>
#include <QPlainTextEdit>
#include <QPushButton>
#include <QQmlEngine>
#include <QRadioButton>
#include <QRegularExpression>
#include <QLocale>
#include <QTranslator>
#include <QScrollArea>
#include <QSettings>
#include <QSplitter>
#include <QStandardPaths>
#include <QSet>
#include <QTabWidget>
#include <QTimer>
#include <QTreeWidget>
#include <QTreeWidgetItemIterator>
#include <QUrl>
#include <QUrlQuery>
#include <QVBoxLayout>

#include <KAuth/Action>
#include <KAuth/ExecuteJob>
#include <KAuthorized>
#include <KCModule>
#include <KCModuleLoader>
#include <KJob>
#include <KPluginMetaData>

#include <algorithm>
#include <functional>
#include <initializer_list>
#include <memory>

namespace {

QIcon sidebarIcon(const QString &name)
{
    const QIcon source = QIcon::fromTheme(name);
    if (source.isNull()) return source;
    QIcon result;
    for (const int size : {16, 22, 32, 48}) {
        const QPixmap original = source.pixmap(size, size);
        if (original.isNull()) continue;
        QPixmap tinted(original.size());
        tinted.fill(Qt::transparent);
        QPainter painter(&tinted);
        painter.drawPixmap(0, 0, original);
        painter.setCompositionMode(QPainter::CompositionMode_SourceIn);
        painter.fillRect(tinted.rect(), QColor(QStringLiteral("#d9e7ef")));
        painter.end();
        result.addPixmap(tinted);
    }
    return result.isNull() ? source : result;
}

struct EczosPage {
    QString id;
    QString name;
    QString description;
    QString icon;
};

const QList<EczosPage> &eczosPages()
{
    static const QList<EczosPage> pages = {
        {QStringLiteral("eczos:overview"), QObject::tr("Overview"), QObject::tr("Everything for your computer"), QStringLiteral("go-home")},
        {QStringLiteral("eczos:hardware"), QObject::tr("Hardware profile"), QObject::tr("Memory, storage and performance profile"), QStringLiteral("preferences-system-performance")},
        {QStringLiteral("eczos:boot"), QObject::tr("Startup and operating systems"), QObject::tr("Detect systems and manage the boot menu safely"), QStringLiteral("system-reboot")},
        {QStringLiteral("eczos:windows"), QObject::tr("Windows apps"), QObject::tr("Manage Windows programs"), QStringLiteral("application-x-ms-dos-executable")},
        {QStringLiteral("eczos:gaming"), QObject::tr("Gaming"), QObject::tr("Check Steam, Proton and Vulkan"), QStringLiteral("applications-games")},
        {QStringLiteral("eczos:remote-input"), QObject::tr("Keyboard and mouse sharing"), QObject::tr("Use one keyboard and mouse across computers"), QStringLiteral("input-keyboard")},
        {QStringLiteral("eczos:network-shares"), QObject::tr("Network shares"), QObject::tr("Open shared folders and servers"), QStringLiteral("folder-network")},
        {QStringLiteral("eczos:network-optical"), QObject::tr("Network optical drives"), QObject::tr("Share and connect CD, DVD and Blu-ray drives"), QStringLiteral("media-optical")},
        {QStringLiteral("eczos:recovery"), QObject::tr("Recovery media"), QObject::tr("Create an ECZOS medium"), QStringLiteral("drive-removable-media")},
        {QStringLiteral("eczos:migration"), QObject::tr("Transfer files"), QObject::tr("Bring files over from Windows"), QStringLiteral("folder-sync")},
        {QStringLiteral("eczos:diagnostics"), QObject::tr("Diagnostics"), QObject::tr("Check your computer"), QStringLiteral("tools-report-bug")},
        {QStringLiteral("eczos:support"), QObject::tr("Support"), QObject::tr("Create a support report"), QStringLiteral("help-support")},
    };
    return pages;
}

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
        return QObject::tr("System information");
    }
    if (containsAny({"lookandfeel", "style", "color", "icon", "cursor", "font", "splash", "wallpaper", "decoration", "theme"})) {
        return QObject::tr("Appearance");
    }
    if (containsAny({"network", "proxy", "firewall", "bluetooth", "bolt", "samba", "webshortcut", "kdeconnect"})) {
        return QObject::tr("Network and connections");
    }
    if (containsAny({"audio", "sound", "mouse", "keyboard", "touch", "screen", "display", "power", "energy", "printer", "tablet", "controller", "kamera", "automount"})) {
        return QObject::tr("Devices and power");
    }
    if (containsAny({"region", "language", "spell", "user", "clock", "time", "date", "account"})) {
        return QObject::tr("Language, time and accounts");
    }
    if (containsAny({"locker", "wallet", "permission", "privacy", "feedback", "security", "recent"})) {
        return QObject::tr("Privacy and security");
    }
    return QObject::tr("Workspace and behaviour");
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
    QJsonArray customPages;
    for (const EczosPage &page : eczosPages()) {
        customPages.append(QJsonObject{{QStringLiteral("id"), page.id}, {QStringLiteral("name"), page.name}});
    }
    for (const KPluginMetaData &data : modules) {
        records.append(QJsonObject{
            {QStringLiteral("id"), data.pluginId()},
            {QStringLiteral("name"), data.name()},
            {QStringLiteral("description"), data.description()},
            {QStringLiteral("category"), categoryFor(data)},
        });
    }
    return QJsonDocument(QJsonObject{{QStringLiteral("schemaVersion"), 1},
                                     {QStringLiteral("eczosPages"), customPages},
                                     {QStringLiteral("modules"), records}});
}

class SettingsWindow final : public QMainWindow
{
    Q_OBJECT

public:
    explicit SettingsWindow(const QList<KPluginMetaData> &modules)
        : m_modules(modules)
        , m_engine(std::make_shared<QQmlEngine>())
    {
        setWindowTitle(tr("ECZOS Settings"));
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
        m_search->setPlaceholderText(tr("Search all settings…"));
        m_search->setClearButtonEnabled(true);
        sideLayout->addWidget(m_search);

        m_tree = new QTreeWidget(sidebar);
        m_tree->setHeaderHidden(true);
        m_tree->setRootIsDecorated(false);
        m_tree->setIndentation(0);
        m_tree->setAnimated(true);
        sideLayout->addWidget(m_tree, 1);

        QSettings settings(QStringLiteral("EasyComp Zeeland"), QStringLiteral("ECZOS System Settings"));
        m_advancedMode = settings.value(QStringLiteral("ui/advancedMode"), false).toBool();
        auto *advancedMode = new QCheckBox(tr("Advanced mode"), sidebar);
        advancedMode->setChecked(m_advancedMode);
        advancedMode->setToolTip(tr("Show technical details and specialist maintenance tools."));
        sideLayout->addWidget(advancedMode);

        auto *identity = new QLabel(QStringLiteral("EasyComp Zeeland\nOperating System"), sidebar);
        identity->setObjectName(QStringLiteral("identity"));
        sideLayout->addWidget(identity);
        outer->addWidget(sidebar);

        m_content = new QWidget(central);
        m_contentLayout = new QVBoxLayout(m_content);
        m_contentLayout->setContentsMargins(22, 18, 22, 16);
        m_contentLayout->setSpacing(12);
        m_heading = new QLabel(tr("System settings"), m_content);
        m_heading->setObjectName(QStringLiteral("pageHeading"));
        m_description = new QLabel(tr("Choose a module on the left. All settings remain in this window."), m_content);
        m_description->setObjectName(QStringLiteral("pageDescription"));
        m_description->setWordWrap(true);
        m_contentLayout->addWidget(m_heading);
        m_contentLayout->addWidget(m_description);

        m_moduleArea = new QScrollArea(m_content);
        m_moduleArea->setWidgetResizable(true);
        m_moduleArea->setFrameShape(QFrame::NoFrame);
        m_contentLayout->addWidget(m_moduleArea, 1);

        m_buttons = new QDialogButtonBox(m_content);
        m_apply = m_buttons->addButton(tr("Save"), QDialogButtonBox::ApplyRole);
        m_reset = m_buttons->addButton(tr("Undo changes"), QDialogButtonBox::ResetRole);
        m_defaults = m_buttons->addButton(tr("Defaults"), QDialogButtonBox::ResetRole);
        m_help = m_buttons->addButton(tr("Help"), QDialogButtonBox::HelpRole);
        m_contentLayout->addWidget(m_buttons);
        outer->addWidget(m_content, 1);

        setStyleSheet(QStringLiteral(R"(
            #sidebar { background: #0b1926; border-right: 1px solid #152c3e; }
            #sidebar QLineEdit { min-height: 38px; padding: 0 11px; color: #f4f8fb; background: #172a3b; border: 1px solid #294156; border-radius: 9px; }
            #sidebar QTreeWidget { color: #eaf3f8; background: transparent; border: 0; outline: 0; }
            #sidebar QTreeWidget::item { min-height: 34px; padding: 2px 6px; border-radius: 7px; }
            #sidebar QTreeWidget::item:selected { background: #183b52; color: #ffffff; }
            #sidebar QTreeWidget::item:hover { background: #132b3d; }
            #sidebar QTreeWidget::branch { background: transparent; }
            #sidebar QCheckBox { color: #d9e7ef; padding: 6px; }
            #identity { color: #6f8da2; font-size: 11px; }
            #pageHeading { font-size: 25px; font-weight: 700; }
            #pageDescription { color: palette(mid); font-size: 13px; }
        )"));

        populateTree();
        if (m_tree->topLevelItemCount() > 0 && m_tree->topLevelItem(0)->childCount() > 0) {
            m_tree->setCurrentItem(m_tree->topLevelItem(0)->child(0));
        }
        showCustomPage(QStringLiteral("eczos:overview"));
        connect(m_search, &QLineEdit::textChanged, this, &SettingsWindow::filterTree);
        connect(m_tree, &QTreeWidget::itemActivated, this, &SettingsWindow::activateItem);
        connect(m_tree, &QTreeWidget::itemClicked, this, &SettingsWindow::activateItem);
        connect(advancedMode, &QCheckBox::toggled, this, [this](bool enabled) {
            m_advancedMode = enabled;
            QSettings(QStringLiteral("EasyComp Zeeland"), QStringLiteral("ECZOS System Settings"))
                .setValue(QStringLiteral("ui/advancedMode"), enabled);
            QTreeWidgetItem *current = m_tree->currentItem();
            const QString id = current ? current->data(0, Qt::UserRole).toString() : QString();
            if (id.startsWith(QStringLiteral("eczos:")) && (!m_task || m_task->state() == QProcess::NotRunning)) {
                showCustomPage(id);
            }
        });
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

    bool openEntry(const QString &id)
    {
        if (id == QStringLiteral("eczos:time")) {
            return openEntry(QStringLiteral("kcm_clock"));
        }
        const bool isCustom = id.startsWith(QStringLiteral("eczos:"));
        if (!isCustom && !m_byId.contains(id)) {
            return false;
        }
        for (QTreeWidgetItemIterator it(m_tree); *it; ++it) {
            if ((*it)->data(0, Qt::UserRole).toString() == id) {
                m_tree->setCurrentItem(*it);
                if (isCustom) {
                    showCustomPage(id);
                } else {
                    loadModule(id);
                }
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
        const QSet<QString> lowContrastKdeIcons{
            QStringLiteral("kcm_soundtheme"),
            QStringLiteral("kcm_device_automounter"),
            QStringLiteral("kcm_kamera"),
            QStringLiteral("kcm_kscreen"),
            QStringLiteral("kcm_updates"),
            QStringLiteral("kcm_audio_information"),
            QStringLiteral("kcm_block_devices"),
            QStringLiteral("kcm_autostart"),
            QStringLiteral("kcm_fcitx5"),
            QStringLiteral("kcm_nightlight"),
            QStringLiteral("kcm_usb"),
            QStringLiteral("kcm_smserver"),
            QStringLiteral("kcm_solid_actions"),
        };
        auto *eczosGroup = new QTreeWidgetItem(m_tree, QStringList(QStringLiteral("ECZOS")));
        eczosGroup->setFlags(Qt::ItemIsEnabled);
        eczosGroup->setExpanded(true);
        for (const EczosPage &page : eczosPages()) {
            auto *item = new QTreeWidgetItem(eczosGroup, QStringList(page.name));
            item->setToolTip(0, page.description);
            item->setData(0, Qt::UserRole, page.id);
            item->setIcon(0, sidebarIcon(page.icon));
        }
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
            item->setIcon(0, lowContrastKdeIcons.contains(data.pluginId())
                ? sidebarIcon(data.iconName()) : QIcon::fromTheme(data.iconName()));
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
                    || item->toolTip(0).contains(query, Qt::CaseInsensitive)
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
            if (id.startsWith(QStringLiteral("eczos:"))) {
                showCustomPage(id);
            } else {
                loadModule(id);
            }
        }
    }

    void clearPage()
    {
        QWidget *oldWidget = m_moduleArea->takeWidget();
        if (m_module) {
            delete m_module;
            m_module = nullptr;
        }
        delete oldWidget;
        m_buttons->hide();
    }

    void setCustomContent(QWidget *page, const QString &heading, const QString &description)
    {
        clearPage();
        m_heading->setText(heading);
        m_description->setText(description);
        m_moduleArea->setWidget(page);
    }

    QVBoxLayout *pageLayout(QWidget *page)
    {
        auto *layout = new QVBoxLayout(page);
        layout->setContentsMargins(8, 8, 8, 18);
        layout->setSpacing(14);
        return layout;
    }

    QGroupBox *statusCard(const QString &title, const QString &detail, bool okay, QWidget *parent)
    {
        auto *card = new QGroupBox(title, parent);
        auto *layout = new QHBoxLayout(card);
        auto *state = new QLabel(okay ? QStringLiteral("✓") : QStringLiteral("!"), card);
        state->setStyleSheet(okay ? QStringLiteral("color: #15956f; font-size: 24px; font-weight: 700;")
                                  : QStringLiteral("color: #d18b21; font-size: 24px; font-weight: 700;"));
        auto *text = new QLabel(detail, card);
        text->setWordWrap(true);
        layout->addWidget(state);
        layout->addWidget(text, 1);
        return card;
    }

    void navigateTo(const QString &id)
    {
        for (QTreeWidgetItemIterator it(m_tree); *it; ++it) {
            if ((*it)->data(0, Qt::UserRole).toString() == id) {
                m_tree->setCurrentItem(*it);
                showCustomPage(id);
                return;
            }
        }
    }

    void setTaskFeedback(QLabel *status, QProgressBar *progress = nullptr)
    {
        m_taskStatus = status;
        m_taskProgress = progress;
        if (m_taskProgress) {
            m_taskProgress->setRange(0, 1000);
            m_taskProgress->setValue(0);
        }
    }

    void startTask(const QString &kind,
                   const QString &program,
                   const QStringList &arguments,
                   const QString &initialStatus,
                   std::function<void(int, const QByteArray &, const QByteArray &)> done = {})
    {
        if (m_task && m_task->state() != QProcess::NotRunning) {
            if (m_taskStatus) {
                m_taskStatus->setText(tr("A task is already running."));
            }
            return;
        }
        if (!QFileInfo::exists(program)) {
            if (m_taskStatus) {
                m_taskStatus->setText(tr("This ECZOS component is not installed."));
            }
            return;
        }
        m_taskKind = kind;
        m_taskStdout.clear();
        m_taskStderr.clear();
        m_eventBuffer.clear();
        m_taskDone = std::move(done);
        m_tree->setEnabled(false);
        if (m_taskStatus) {
            m_taskStatus->setText(initialStatus);
        }
        if (m_taskProgress) {
            m_taskProgress->setValue(0);
            m_taskProgress->show();
        }
        m_task = new QProcess(this);
        connect(m_task, &QProcess::readyReadStandardOutput, this, [this] {
            const QByteArray chunk = m_task->readAllStandardOutput();
            m_taskStdout += chunk;
            m_eventBuffer += chunk;
            while (m_eventBuffer.contains('\n')) {
                const QByteArray line = m_eventBuffer.left(m_eventBuffer.indexOf('\n'));
                m_eventBuffer.remove(0, m_eventBuffer.indexOf('\n') + 1);
                if (!line.startsWith("ECZOS_EVENT ")) {
                    continue;
                }
                const QJsonObject event = QJsonDocument::fromJson(line.mid(12)).object();
                if (event.value(QStringLiteral("type")).toString() == QStringLiteral("progress")) {
                    if (m_taskProgress) {
                        m_taskProgress->setValue(qRound(event.value(QStringLiteral("fraction")).toDouble() * 1000));
                    }
                    if (m_taskStatus) {
                        m_taskStatus->setText(event.value(QStringLiteral("message")).toString());
                    }
                }
            }
        });
        connect(m_task, &QProcess::readyReadStandardError, this, [this] { m_taskStderr += m_task->readAllStandardError(); });
        connect(m_task, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
                [this](int exitCode, QProcess::ExitStatus) {
                    m_taskStdout += m_task->readAllStandardOutput();
                    m_taskStderr += m_task->readAllStandardError();
                    const QByteArray output = m_taskStdout;
                    const QByteArray errors = m_taskStderr;
                    auto callback = std::move(m_taskDone);
                    m_task->deleteLater();
                    m_task = nullptr;
                    m_tree->setEnabled(true);
                    if (m_taskProgress && exitCode == 0) {
                        m_taskProgress->setValue(1000);
                    }
                    if (callback) {
                        callback(exitCode, output, errors);
                    } else if (m_taskStatus) {
                        const QString detail = QString::fromUtf8(exitCode == 0 ? output : errors).trimmed();
                        m_taskStatus->setText(exitCode == 0 ? tr("Done")
                                                           : (detail.isEmpty() ? tr("The task failed.") : detail.section('\n', -1)));
                    }
                });
        m_task->start(program, arguments);
    }

    void showOverviewPage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        auto *intro = new QLabel(tr("Manage ECZOS and all system components from one window."), page);
        intro->setStyleSheet(QStringLiteral("font-size: 18px; font-weight: 600; padding: 8px;"));
        intro->setWordWrap(true);
        layout->addWidget(intro);
        auto *grid = new QGridLayout;
        int index = 0;
        for (const EczosPage &entry : eczosPages()) {
            if (entry.id == QStringLiteral("eczos:overview")) {
                continue;
            }
            auto *button = new QPushButton(QIcon::fromTheme(entry.icon), entry.name + QStringLiteral("\n") + entry.description, page);
            button->setMinimumHeight(82);
            button->setIconSize(QSize(34, 34));
            connect(button, &QPushButton::clicked, this, [this, id = entry.id] { navigateTo(id); });
            grid->addWidget(button, index / 2, index % 2);
            ++index;
        }
        const auto addAction = [this, page, grid, &index](const QString &title, const QString &description,
                                                          const QString &icon, const std::function<void()> &action,
                                                          bool enabled = true) {
            auto *button = new QPushButton(QIcon::fromTheme(icon), title + QStringLiteral("\n") + description, page);
            button->setMinimumHeight(82);
            button->setIconSize(QSize(34, 34));
            button->setEnabled(enabled);
            connect(button, &QPushButton::clicked, this, action);
            grid->addWidget(button, index / 2, index % 2);
            ++index;
        };
        addAction(tr("Apps"), tr("Install and update applications"), QStringLiteral("plasmadiscover"),
                  [] { QProcess::startDetached(QStringLiteral("plasma-discover"), {}); });
        addAction(tr("Backup"), tr("Protect your personal files"), QStringLiteral("kup"),
                  [this] { openEntry(QStringLiteral("kcm_kup")); }, m_byId.contains(QStringLiteral("kcm_kup")));
        addAction(tr("Phone"), tr("Connect your phone to ECZOS"), QStringLiteral("kdeconnect"),
                  [this] { openEntry(QStringLiteral("kcm_kdeconnect")); }, m_byId.contains(QStringLiteral("kcm_kdeconnect")));
        addAction(tr("About this computer"), tr("View hardware and system information"), QStringLiteral("help-about"),
                  [this] { openEntry(QStringLiteral("kcm_about-distro")); }, m_byId.contains(QStringLiteral("kcm_about-distro")));
        layout->addLayout(grid);
        layout->addStretch(1);
        setCustomContent(page, tr("Everything for your computer"), tr("ECZOS features and system settings in one place."));
    }

    void showWindowsPage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        const QFileInfo windowsManager(QStringLiteral("/usr/bin/eczos-windows"));
        if (!windowsManager.isExecutable()) {
            auto *unavailable = new QLabel(
                tr("Windows app support is not installed. Install the ECZOS Windows feature to use this page."), page);
            unavailable->setWordWrap(true);
            unavailable->setAlignment(Qt::AlignCenter);
            unavailable->setMinimumHeight(160);
            layout->addWidget(unavailable);
            layout->addStretch(1);
            setCustomContent(page, tr("Windows apps"), tr("This optional ECZOS feature is currently unavailable."));
            return;
        }
        // This is an idempotent, local metadata migration. It never starts
        // Wine or recreates an application's existing prefix.
        QProcess::execute(QStringLiteral("/usr/bin/eczos-windows"), {QStringLiteral("migrate")});
        auto *toolbar = new QHBoxLayout;
        auto *summary = new QLabel(tr("Each Windows program is managed in its own separate environment."), page);
        summary->setWordWrap(true);
        auto *installApp = new QPushButton(tr("Install EXE or MSI"), page);
        auto *refresh = new QPushButton(tr("Refresh list"), page);
        toolbar->addWidget(summary, 1);
        toolbar->addWidget(installApp);
        toolbar->addWidget(refresh);
        layout->addLayout(toolbar);
        auto *status = new QLabel(page);
        status->setWordWrap(true);
        status->setText(tr("Ready. Choose an action for an application below."));
        layout->addWidget(status);
        const QString appsRoot = QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation) + QStringLiteral("/eczos/windows/apps");
        int count = 0;
        QDirIterator manifests(appsRoot, QStringList{QStringLiteral("manifest.json")}, QDir::Files, QDirIterator::Subdirectories);
        while (manifests.hasNext()) {
            const QString path = manifests.next();
            QFile file(path);
            if (!file.open(QIODevice::ReadOnly)) {
                continue;
            }
            const QJsonObject record = QJsonDocument::fromJson(file.readAll()).object();
            const QString id = record.value(QStringLiteral("id")).toString();
            if (id.isEmpty()) {
                continue;
            }
            ++count;
            QString displayName = record.value(QStringLiteral("name")).toString().trimmed();
            if (displayName.isEmpty()) {
                displayName = QFileInfo(record.value(QStringLiteral("entrypoint")).toString()).completeBaseName().trimmed();
            }
            if (displayName.isEmpty()) {
                displayName = id;
            }
            auto *card = new QGroupBox(displayName, page);
            card->setStyleSheet(QStringLiteral("QGroupBox { font-weight: 600; margin-top: 12px; } "
                                               "QGroupBox::title { subcontrol-origin: margin; left: 12px; padding: 0 5px; }"));
            auto *cardLayout = new QVBoxLayout(card);
            auto *header = new QHBoxLayout;
            const QString iconValue = record.value(QStringLiteral("icon")).toString();
            QIcon appIcon = iconValue.startsWith(QLatin1Char('/')) ? QIcon(iconValue) : QIcon::fromTheme(iconValue);
            if (appIcon.isNull()) {
                appIcon = QIcon::fromTheme(QStringLiteral("application-x-ms-dos-executable"));
            }
            auto *icon = new QLabel(card);
            icon->setPixmap(appIcon.pixmap(QSize(42, 42)));
            icon->setFixedSize(50, 50);
            icon->setAlignment(Qt::AlignCenter);
            header->addWidget(icon);
            const QString appStatus = record.value(QStringLiteral("status")).toString();
            const bool hasEntrypoint = !record.value(QStringLiteral("entrypoint")).toString().trimmed().isEmpty();
            const QJsonArray compatibilityBlockers = record.value(QStringLiteral("compatibility")).toObject()
                                                        .value(QStringLiteral("blockers")).toArray();
            QString blockerId;
            for (const QJsonValue &value : compatibilityBlockers) {
                const QJsonObject blocker = value.toObject();
                if (blocker.value(QStringLiteral("severity")).toString() == QStringLiteral("blocked")) {
                    blockerId = blocker.value(QStringLiteral("id")).toString();
                    break;
                }
            }
            const bool compatibilityBlocked = !blockerId.isEmpty();
            QString runner = record.value(QStringLiteral("runner")).toObject().value(QStringLiteral("id")).toString().trimmed();
            if (runner.isEmpty()) runner = record.value(QStringLiteral("runtime")).toString().trimmed();
            if (runner.isEmpty()) runner = QStringLiteral("Wine");
            QString stateText;
            if (blockerId == QStringLiteral("safedisc-driver")) stateText = tr("Cannot start: obsolete SafeDisc disc protection");
            else if (compatibilityBlocked) stateText = tr("Cannot start with the current compatibility engine");
            else if (appStatus == QStringLiteral("installed")) stateText = tr("Installed and ready");
            else if (appStatus == QStringLiteral("installer-failed")) stateText = tr("Installation needs attention");
            else if (appStatus == QStringLiteral("installed-needs-entrypoint")) stateText = tr("Installed program not found yet");
            else if (appStatus == QStringLiteral("runtime-initialization-failed")) stateText = tr("Windows environment needs repair");
            else if (appStatus == QStringLiteral("media-copy-failed")) stateText = tr("Installation media could not be copied");
            else if (appStatus == QStringLiteral("copying-media")) stateText = tr("Copying installation media…");
            else if (appStatus == QStringLiteral("initializing")) stateText = tr("Preparing Windows environment…");
            else if (appStatus == QStringLiteral("rerunning-installer")) stateText = tr("Setup is running…");
            else stateText = tr("Needs attention");
            QString detailText = m_advancedMode ? tr("%1\nCompatibility engine: %2").arg(stateText, runner) : stateText;
            if (blockerId == QStringLiteral("safedisc-driver")) {
                detailText += QStringLiteral("\n") + tr("The original disc needs a publisher update or legitimate DRM-free release; adding runtimes cannot repair this.");
            }
            auto *detail = new QLabel(detailText, card);
            detail->setWordWrap(true);
            detail->setStyleSheet(compatibilityBlocked
                                      ? QStringLiteral("color: #b3261e;")
                                      : appStatus == QStringLiteral("installed")
                                      ? QStringLiteral("color: #15805f;")
                                      : QStringLiteral("color: palette(mid);"));
            header->addWidget(detail, 1);
            cardLayout->addLayout(header);

            struct WindowsAction {
                QString label;
                QString description;
                QString icon;
                QString action;
            };
            const QList<WindowsAction> actions{
                {tr("Start app\nOpen the program"), tr("Start this Windows application."), QStringLiteral("media-playback-start"), QStringLiteral("run")},
                {tr("App settings\nAdvanced Windows tools"), tr("Open Wine settings and Windows maintenance tools for only this app."), QStringLiteral("configure"), QStringLiteral("configure")},
                {tr("Components\nAdd required runtimes"), tr("Install optional components such as Visual C++, .NET or classic-game support."), QStringLiteral("package-x-generic"), QStringLiteral("dependencies")},
                {tr("Program file\nChoose another EXE"), tr("Change which installed executable is started for this app."), QStringLiteral("application-x-executable"), QStringLiteral("set-entrypoint")},
                {tr("Run setup again\nUse the saved installer"), tr("Run the original installer again without deleting this app."), QStringLiteral("system-software-install"), QStringLiteral("retry-installer")},
                {tr("Find program again\nRepair a missing launcher"), tr("Search the managed Windows environment for the correct program file."), QStringLiteral("edit-find"), QStringLiteral("rescan")},
                {tr("Check and repair\nFix this app automatically"), tr("Check the isolated Windows environment and automatically repair known problems."), QStringLiteral("tools-wizard"), QStringLiteral("repair")},
                {tr("Remove app\nDelete app and its data"), tr("Remove this app and its separate Windows environment."), QStringLiteral("edit-delete"), QStringLiteral("remove")},
            };
            auto *buttonGrid = new QGridLayout;
            for (int column = 0; column < 3; ++column) buttonGrid->setColumnStretch(column, 1);
            int actionIndex = 0;
            for (const WindowsAction &entry : actions) {
                const QString &action = entry.action;
                auto *button = new QPushButton(QIcon::fromTheme(entry.icon), entry.label, card);
                button->setToolTip(entry.description);
                button->setAccessibleDescription(entry.description);
                button->setMinimumHeight(58);
                button->setIconSize(QSize(24, 24));
                        button->setEnabled(action != QStringLiteral("run")
                                   || (appStatus == QStringLiteral("installed") && hasEntrypoint && !compatibilityBlocked));
                if (action == QStringLiteral("retry-installer")) {
                    button->setVisible(appStatus == QStringLiteral("installer-failed")
                                       || appStatus == QStringLiteral("installed-needs-entrypoint")
                                       || appStatus == QStringLiteral("rerunning-installer"));
                } else if (action == QStringLiteral("configure")) {
                    button->setVisible(m_advancedMode);
                }
                const QString currentEntrypoint = record.value(QStringLiteral("entrypoint")).toString();
                const QString managedPrefix = record.value(QStringLiteral("prefix")).toString();
                connect(button, &QPushButton::clicked, this,
                        [this, id, action, name = displayName, status, currentEntrypoint, managedPrefix] {
                    if (action == QStringLiteral("run")) {
                        status->setText(tr("Starting %1…").arg(name));
                        auto *launch = new QProcess(this);
                        const QPointer<QLabel> launchStatus(status);
                        connect(launch, &QProcess::started, this, [launchStatus, name] {
                            if (launchStatus) launchStatus->setText(QObject::tr("%1 is starting…").arg(name));
                        });
                        connect(launch, &QProcess::errorOccurred, this, [this, launchStatus, name, launch](QProcess::ProcessError) {
                            const QString detail = launch->errorString();
                            const QString message = tr("%1 could not be started: %2").arg(name, detail);
                            if (launchStatus) launchStatus->setText(message);
                            QMessageBox::warning(this, tr("Windows app could not start"), message);
                        });
                        connect(launch, qOverload<int, QProcess::ExitStatus>(&QProcess::finished), this,
                                [this, launchStatus, name, launch](int code, QProcess::ExitStatus exitStatus) {
                            const QString detail = QString::fromUtf8(launch->readAllStandardError()).trimmed().section('\n', -1);
                            if (exitStatus == QProcess::CrashExit || code != 0) {
                                const QString message = detail.isEmpty()
                                    ? tr("%1 stopped before it could start. Choose ‘Check and repair’ and try again.").arg(name)
                                    : detail;
                                if (launchStatus) launchStatus->setText(message);
                                QMessageBox::warning(this, tr("Windows app needs attention"), message);
                            } else {
                                if (launchStatus) launchStatus->setText(tr("%1 has closed.").arg(name));
                            }
                            launch->deleteLater();
                        });
                        launch->start(QStringLiteral("/usr/bin/eczos-windows"), {action, id});
                        return;
                    }
                    if (action == QStringLiteral("configure")) {
                        const QStringList labels{
                            tr("Wine configuration"), tr("Windows Control Panel"), tr("Registry Editor"),
                            tr("Task Manager"), tr("Uninstall a program"), tr("File Explorer"), tr("Command Prompt")};
                        const QStringList tools{
                            QStringLiteral("winecfg"), QStringLiteral("control"), QStringLiteral("regedit"),
                            QStringLiteral("taskmgr"), QStringLiteral("uninstaller"), QStringLiteral("explorer"),
                            QStringLiteral("cmd")};
                        bool accepted = false;
                        const QString selection = QInputDialog::getItem(
                            this, tr("Windows app settings"), tr("Choose a tool for %1:").arg(name), labels, 0, false, &accepted);
                        const int toolIndex = labels.indexOf(selection);
                        if (accepted && toolIndex >= 0) {
                            QProcess::startDetached(QStringLiteral("/usr/bin/eczos-windows"),
                                                    {QStringLiteral("configure"), id, tools.at(toolIndex)});
                        }
                        return;
                    }
                    if (action == QStringLiteral("dependencies")) {
                        setTaskFeedback(status);
                        startTask(QStringLiteral("windows-dependencies"), QStringLiteral("/usr/bin/eczos-windows"),
                                  {QStringLiteral("dependencies"), QStringLiteral("--json"), id},
                                  tr("Checking installed Windows components…"),
                                  [this, id, name, status](int code, const QByteArray &output, const QByteArray &errors) {
                                      const QJsonArray components = QJsonDocument::fromJson(output).array();
                                      if (code != 0 || components.isEmpty()) {
                                          const QString detail = QString::fromUtf8(errors).trimmed();
                                          status->setText(detail.isEmpty() ? tr("No Windows components are available.")
                                                                           : detail.section('\n', -1));
                                          return;
                                      }
                                      QStringList labels;
                                      QStringList ids;
                                      for (const QJsonValue &value : components) {
                                          const QJsonObject component = value.toObject();
                                          const bool installed = component.value(QStringLiteral("installed")).toBool();
                                          labels << QStringLiteral("%1%2 — %3")
                                                        .arg(installed ? QStringLiteral("✓ ") : QString(),
                                                             component.value(QStringLiteral("name")).toString(),
                                                             component.value(QStringLiteral("description")).toString());
                                          ids << component.value(QStringLiteral("id")).toString();
                                      }
                                      bool accepted = false;
                                      const QString selection = QInputDialog::getItem(
                                          this, tr("Windows components for %1").arg(name),
                                          tr("Installed components have a check mark. Choose a missing component to install:"),
                                          labels, 0, false, &accepted);
                                      const int selected = labels.indexOf(selection);
                                      if (!accepted || selected < 0 || selection.startsWith(QStringLiteral("✓ "))) {
                                          status->setText(selection.startsWith(QStringLiteral("✓ "))
                                                              ? tr("This component is already installed.")
                                                              : tr("No changes made."));
                                          return;
                                      }
                                      if (QMessageBox::question(
                                              this, tr("Install Windows component"),
                                              tr("Install this component only for ‘%1’? Other Windows apps remain unchanged.").arg(name))
                                          != QMessageBox::Yes) {
                                          status->setText(tr("No changes made."));
                                          return;
                                      }
                                      setTaskFeedback(status);
                                      startTask(QStringLiteral("windows-dependency-install"),
                                                QStringLiteral("/usr/bin/eczos-windows"),
                                                {QStringLiteral("install-dependency"), QStringLiteral("--yes"), id,
                                                 ids.at(selected)},
                                                tr("Installing Windows component…"),
                                                [this, status](int installCode, const QByteArray &installOutput,
                                                               const QByteArray &installErrors) {
                                                    const QString message = QString::fromUtf8(
                                                        installCode == 0 ? installOutput : installErrors).trimmed();
                                                    status->setText(message.isEmpty()
                                                                        ? (installCode == 0 ? tr("Windows component installed.")
                                                                                            : tr("Installing the component failed."))
                                                                        : message.section('\n', -1));
                                                });
                                  });
                        return;
                    }
                    if (action == QStringLiteral("set-entrypoint")) {
                        QString startLocation = currentEntrypoint;
                        if (!QFileInfo::exists(startLocation)) {
                            startLocation = managedPrefix + QStringLiteral("/drive_c");
                        }
                        const QString executable = QFileDialog::getOpenFileName(
                            this, tr("Choose the program file for %1").arg(name), startLocation,
                            tr("Windows executable (*.exe)"));
                        if (executable.isEmpty()) {
                            status->setText(tr("No changes made."));
                            return;
                        }
                        if (QMessageBox::question(
                                this, tr("Change program file"),
                                tr("Start ‘%1’ with this executable from now on?\n\n%2").arg(name, executable))
                            != QMessageBox::Yes) {
                            status->setText(tr("No changes made."));
                            return;
                        }
                        setTaskFeedback(status);
                        startTask(QStringLiteral("windows-entrypoint"), QStringLiteral("/usr/bin/eczos-windows"),
                                  {QStringLiteral("set-entrypoint"), id, executable},
                                  tr("Saving the selected program file…"),
                                  [this, status](int code, const QByteArray &output, const QByteArray &errors) {
                                      const QString message = QString::fromUtf8(code == 0 ? output : errors).trimmed();
                                      if (code == 0) {
                                          showWindowsPage();
                                      } else {
                                          const QString detail = message.isEmpty()
                                              ? tr("The selected program file could not be saved.")
                                              : message.section('\n', -1);
                                          status->setText(detail);
                                          QMessageBox::warning(this, tr("Program file not changed"), detail);
                                      }
                                  });
                        return;
                    }
                    if (action == QStringLiteral("retry-installer")) {
                        if (QMessageBox::question(
                                this, tr("Run setup again"),
                                tr("Run the cached setup for ‘%1’ again in the same Windows environment?").arg(name))
                            != QMessageBox::Yes) {
                            return;
                        }
                        setTaskFeedback(status);
                        startTask(QStringLiteral("windows-installer-retry"), QStringLiteral("/usr/bin/eczos-windows"),
                                  {QStringLiteral("retry-installer"), QStringLiteral("--yes"), id},
                                  tr("Running setup again…"),
                                  [this, status](int code, const QByteArray &output, const QByteArray &errors) {
                                      const QString message = QString::fromUtf8(code == 0 ? output : errors).trimmed();
                                      if (code == 0) {
                                          showWindowsPage();
                                      } else {
                                          status->setText(message.isEmpty() ? tr("Setup failed again.")
                                                                           : message.section('\n', -1));
                                      }
                                  });
                        return;
                    }
                    if (action == QStringLiteral("remove")
                        && QMessageBox::question(this, tr("Remove Windows app"),
                                                 tr("Remove ‘%1’ and its separate Windows environment?").arg(name)) != QMessageBox::Yes) {
                        return;
                    }
                    setTaskFeedback(status);
                    QStringList arguments{action};
                    if (action == QStringLiteral("remove")) {
                        arguments << QStringLiteral("--yes");
                    }
                    arguments << id;
                    startTask(QStringLiteral("windows"), QStringLiteral("/usr/bin/eczos-windows"), arguments, tr("Working…"),
                              [this, action, name](int code, const QByteArray &output, const QByteArray &errors) {
                                  if (code == 0) {
                                      if (action == QStringLiteral("repair")) {
                                          QMessageBox::information(this, tr("Check and repair complete"),
                                              tr("ECZ Windows checked and repaired the environment for ‘%1’. You can start the app again now.").arg(name));
                                      } else if (action == QStringLiteral("rescan")) {
                                          QMessageBox::information(this, tr("Program search complete"),
                                              tr("ECZ Windows found and registered the start program for ‘%1’.").arg(name));
                                      }
                                      showWindowsPage();
                                  } else if (m_taskStatus) {
                                      QString message = QString::fromUtf8(errors).trimmed().section('\n', -1);
                                      if (message.isEmpty()) message = QString::fromUtf8(output).trimmed().section('\n', -1);
                                      if (message.isEmpty()) message = tr("The requested action could not be completed.");
                                      m_taskStatus->setText(message);
                                      QMessageBox::warning(this, tr("Windows app needs attention"), message);
                                  }
                              });
                });
                buttonGrid->addWidget(button, actionIndex / 3, actionIndex % 3);
                ++actionIndex;
            }
            cardLayout->addLayout(buttonGrid);
            layout->addWidget(card);
        }
        if (count == 0) {
            auto *empty = new QLabel(tr("No Windows apps yet. Open an .exe or .msi file to add an app."), page);
            empty->setAlignment(Qt::AlignCenter);
            empty->setMinimumHeight(130);
            layout->addWidget(empty);
        }
        layout->addStretch(1);
        connect(installApp, &QPushButton::clicked, this, [this] {
            const QString installer = QFileDialog::getOpenFileName(
                this, tr("Install a Windows app"), QDir::homePath(), tr("Windows programs (*.exe *.msi)"));
            if (!installer.isEmpty()) {
                QProcess::startDetached(QStringLiteral("/usr/bin/eczos-windows"), {QStringLiteral("install"), installer});
            }
        });
        connect(refresh, &QPushButton::clicked, this, [this] { showWindowsPage(); });
        setCustomContent(page, tr("Windows apps"), tr("Start, configure, repair and remove Windows programs from one place."));
    }

    void showGamingPage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        auto *cards = new QVBoxLayout;
        layout->addLayout(cards);
        auto *progress = new QProgressBar(page);
        progress->hide();
        auto *status = new QLabel(tr("Checking gaming support…"), page);
        status->setWordWrap(true);
        layout->addWidget(progress);
        layout->addWidget(status);
        auto *actions = new QHBoxLayout;
        auto *repair = new QPushButton(tr("Install missing components"), page);
        auto *check = new QPushButton(tr("Check again"), page);
        auto *steam = new QPushButton(tr("Open Steam"), page);
        actions->addWidget(repair);
        actions->addWidget(check);
        actions->addStretch(1);
        actions->addWidget(steam);
        layout->addLayout(actions);
        layout->addStretch(1);
        const auto checkGaming = [this, cards, status, progress, repair] {
            while (QLayoutItem *item = cards->takeAt(0)) {
                delete item->widget();
                delete item;
            }
            setTaskFeedback(status, progress);
            startTask(QStringLiteral("gaming"), QStringLiteral("/usr/bin/eczos-gaming"),
                      {QStringLiteral("doctor"), QStringLiteral("--json")}, tr("Checking gaming support…"),
                      [this, cards, status, progress, repair](int code, const QByteArray &output, const QByteArray &errors) {
                          progress->hide();
                          const QJsonObject data = QJsonDocument::fromJson(output).object();
                          if (code != 0 || data.isEmpty()) {
                              status->setText(QString::fromUtf8(errors).trimmed().section('\n', -1));
                              return;
                          }
                          const QString verdict = data.value(QStringLiteral("verdict")).toString();
                          const QJsonObject vulkan = data.value(QStringLiteral("vulkan")).toObject();
                          const QJsonObject runtime = data.value(QStringLiteral("runtime")).toObject();
                          cards->addWidget(statusCard(tr("Overall status"), data.value(QStringLiteral("summary")).toString(), verdict == QStringLiteral("ready"), cards->parentWidget()));
                          cards->addWidget(statusCard(tr("Graphics card"), data.value(QStringLiteral("gpu")).toString(tr("Not recognised")), vulkan.value(QStringLiteral("hardware")).toBool(), cards->parentWidget()));
                          cards->addWidget(statusCard(tr("32-bit Vulkan driver"), vulkan.value(QStringLiteral("driver32Bit")).toBool() ? tr("Available") : tr("Missing"), vulkan.value(QStringLiteral("driver32Bit")).toBool(), cards->parentWidget()));
                          cards->addWidget(statusCard(QStringLiteral("UMU/Proton"), runtime.value(QStringLiteral("umu")).toBool() ? tr("Available") : tr("Missing"), runtime.value(QStringLiteral("umu")).toBool(), cards->parentWidget()));
                          cards->addWidget(statusCard(QStringLiteral("GameMode"), runtime.value(QStringLiteral("gameMode")).toBool() ? tr("Available") : tr("Missing"), runtime.value(QStringLiteral("gameMode")).toBool(), cards->parentWidget()));
                          repair->setVisible(verdict == QStringLiteral("setup-required"));
                          status->setText(tr("Check complete"));
                      });
        };
        connect(check, &QPushButton::clicked, this, checkGaming);
        connect(steam, &QPushButton::clicked, this, [] { QProcess::startDetached(QStringLiteral("steam"), {}); });
        connect(repair, &QPushButton::clicked, this, [this, status, progress, checkGaming] {
            setTaskFeedback(status, progress);
            startTask(QStringLiteral("gaming-repair"), QStringLiteral("/usr/bin/pkexec"),
                      {QStringLiteral("/usr/lib/eczos/gaming/repair-runtime")}, tr("Installing gaming support…"),
                      [checkGaming, status](int code, const QByteArray &, const QByteArray &errors) {
                          if (code == 0) {
                              checkGaming();
                          } else {
                              status->setText(QString::fromUtf8(errors).trimmed().section('\n', -1));
                          }
                      });
        });
        setCustomContent(page, QStringLiteral("ECZ Gaming"), tr("Check and repair Steam, Vulkan, classic games and Proton support."));
        checkGaming();
    }

    void showNetworkOpticalPage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        auto *tabs = new QTabWidget(page);
        auto *localPage = new QWidget(tabs);
        auto *networkPage = new QWidget(tabs);
        auto *localLayout = new QVBoxLayout(localPage);
        auto *networkLayout = new QVBoxLayout(networkPage);
        auto *status = new QLabel(tr("Looking for optical drives on this computer and local network…"), page);
        status->setWordWrap(true);
        auto *refresh = new QPushButton(tr("Refresh"), page);
        tabs->addTab(localPage, tr("Share my drives"));
        tabs->addTab(networkPage, tr("Network drives"));
        layout->addWidget(tabs, 1);
        auto *actions = new QHBoxLayout;
        actions->addWidget(status, 1);
        actions->addWidget(refresh);
        layout->addLayout(actions);

        const auto clearCards = [](QVBoxLayout *target) {
            while (QLayoutItem *item = target->takeAt(0)) {
                delete item->widget();
                delete item;
            }
        };
        auto refreshData = std::make_shared<std::function<void()>>();
        const std::weak_ptr<std::function<void()>> weakRefresh = refreshData;
        *refreshData = [this, page, localLayout, networkLayout, status, clearCards, weakRefresh] {
            if (!page->isVisible() || (m_task && m_task->state() != QProcess::NotRunning)) {
                return;
            }
            setTaskFeedback(status);
            startTask(QStringLiteral("network-optical-status"), QStringLiteral("/usr/bin/eczos-network-optical"),
                      {QStringLiteral("status"), QStringLiteral("--json")}, tr("Looking for optical drives…"),
                      [this, page, localLayout, networkLayout, status, clearCards, weakRefresh]
                      (int code, const QByteArray &output, const QByteArray &errors) {
                if (!page->isVisible()) {
                    return;
                }
                const QJsonObject data = QJsonDocument::fromJson(output).object();
                if (code != 0 || data.isEmpty()) {
                    const QString detail = QString::fromUtf8(errors).trimmed();
                    status->setText(detail.isEmpty() ? tr("The network optical drive service is unavailable.")
                                                     : detail.section('\n', -1));
                    return;
                }
                clearCards(localLayout);
                clearCards(networkLayout);
                const QJsonArray local = data.value(QStringLiteral("local")).toArray();
                for (const QJsonValue &value : local) {
                    const QJsonObject drive = value.toObject();
                    auto *card = new QGroupBox(drive.value(QStringLiteral("label")).toString(tr("Optical drive")), page);
                    auto *cardLayout = new QVBoxLayout(card);
                    auto *summary = new QLabel(
                        drive.value(QStringLiteral("capabilities")).toString() + QStringLiteral("\n")
                        + drive.value(QStringLiteral("device")).toString() + QStringLiteral("\n")
                        + (drive.value(QStringLiteral("media")).toBool() ? tr("Media inserted") : tr("No media")), card);
                    summary->setWordWrap(true);
                    cardLayout->addWidget(summary);
                    const bool shared = drive.value(QStringLiteral("shared")).toBool();
                    auto *state = new QLabel(shared
                        ? tr("● Shared on the local network as %1\nServer: %2")
                              .arg(drive.value(QStringLiteral("shareName")).toString(),
                                   drive.value(QStringLiteral("server")).toString())
                        : tr("Not shared"), card);
                    state->setStyleSheet(shared ? QStringLiteral("color: #15956f; font-weight: 600;") : QString());
                    cardLayout->addWidget(state);
                    auto *details = new QLabel(
                        tr("Device: %1\nSCSI generic: %2\nTarget: %3\nProtocol: iSCSI · Port: %4\nBackend: Linux LIO / pSCSI")
                            .arg(drive.value(QStringLiteral("device")).toString(),
                                 drive.value(QStringLiteral("generic")).toString(tr("not available")),
                                 drive.value(QStringLiteral("iqn")).toString(tr("not active")),
                                 QString::number(drive.value(QStringLiteral("port")).toInt(3260))), card);
                    details->setTextInteractionFlags(Qt::TextSelectableByMouse);
                    details->setVisible(false);
                    auto *advanced = new QPushButton(tr("Advanced information"), card);
                    advanced->setCheckable(true);
                    connect(advanced, &QPushButton::toggled, details, &QWidget::setVisible);
                    cardLayout->addWidget(advanced, 0, Qt::AlignLeft);
                    cardLayout->addWidget(details);
                    auto *button = new QPushButton(shared ? tr("Stop sharing") : tr("Share drive"), card);
                    connect(button, &QPushButton::clicked, this, [this, drive, shared, status, weakRefresh] {
                        QStringList arguments{QStringLiteral("/usr/lib/eczos-network-optical/helper")};
                        if (shared) {
                            if (QMessageBox::question(this, tr("Stop sharing this drive?"),
                                                      tr("Connected computers must disconnect before sharing can stop.")) != QMessageBox::Yes) {
                                return;
                            }
                            arguments << QStringLiteral("unshare") << QStringLiteral("--id")
                                      << drive.value(QStringLiteral("id")).toString();
                        } else {
                            bool accepted = false;
                            const QString defaultName = drive.value(QStringLiteral("label")).toString(tr("ECZOS optical drive"));
                            const QString name = QInputDialog::getText(this, tr("Share optical drive"), tr("Name on the local network:"),
                                                                      QLineEdit::Normal, defaultName, &accepted).trimmed();
                            if (!accepted || name.isEmpty()) {
                                return;
                            }
                            arguments << QStringLiteral("share") << QStringLiteral("--device")
                                      << drive.value(QStringLiteral("device")).toString()
                                      << QStringLiteral("--name") << name;
                        }
                        setTaskFeedback(status);
                        startTask(QStringLiteral("network-optical-manage"), QStringLiteral("/usr/bin/pkexec"), arguments,
                                  shared ? tr("Stopping the share…") : tr("Sharing the drive…"),
                                  [status, weakRefresh](int result, const QByteArray &, const QByteArray &taskErrors) {
                            if (result == 0) {
                                if (const auto action = weakRefresh.lock()) (*action)();
                            } else {
                                const QString detail = QString::fromUtf8(taskErrors).trimmed();
                                status->setText(detail.isEmpty() ? QObject::tr("The operation failed.") : detail.section('\n', -1));
                            }
                        });
                    });
                    cardLayout->addWidget(button, 0, Qt::AlignLeft);
                    localLayout->addWidget(card);
                }
                if (local.isEmpty()) {
                    auto *empty = new QLabel(tr("No local physical CD, DVD or Blu-ray drive was found."), page);
                    empty->setAlignment(Qt::AlignCenter);
                    empty->setMinimumHeight(120);
                    localLayout->addWidget(empty);
                }
                localLayout->addStretch(1);

                const QJsonArray network = data.value(QStringLiteral("network")).toArray();
                for (const QJsonValue &value : network) {
                    const QJsonObject drive = value.toObject();
                    auto *card = new QGroupBox(drive.value(QStringLiteral("name")).toString(tr("Network optical drive")), page);
                    auto *cardLayout = new QVBoxLayout(card);
                    const bool connected = drive.value(QStringLiteral("connected")).toBool();
                    auto *summary = new QLabel(
                        drive.value(QStringLiteral("host")).toString() + QStringLiteral("\n")
                        + drive.value(QStringLiteral("vendor")).toString() + QStringLiteral(" ")
                        + drive.value(QStringLiteral("model")).toString() + QStringLiteral("\n")
                        + (connected ? tr("● Connected · Local device: %1").arg(drive.value(QStringLiteral("device")).toString())
                                     : tr("Available")), card);
                    summary->setWordWrap(true);
                    summary->setStyleSheet(connected ? QStringLiteral("color: #15956f;") : QString());
                    cardLayout->addWidget(summary);
                    if (!drive.value(QStringLiteral("managed")).toBool(true)) {
                        auto *legacy = new QLabel(tr("Connected through an existing iSCSI configuration. It can be used normally and will be migrated when its server enables ECZOS sharing."), card);
                        legacy->setWordWrap(true);
                        legacy->setStyleSheet(QStringLiteral("color: palette(mid);"));
                        cardLayout->addWidget(legacy);
                    }
                    auto *autoConnect = new QCheckBox(tr("Connect automatically at startup"), card);
                    autoConnect->setChecked(drive.value(QStringLiteral("automatic")).toBool());
                    autoConnect->setToolTip(tr("Off by default because a physical drive can be used by only one computer at a time."));
                    cardLayout->addWidget(autoConnect);
                    auto *buttons = new QHBoxLayout;
                    auto *primary = new QPushButton(connected ? tr("Disconnect") : tr("Connect"), card);
                    buttons->addWidget(primary);
                    if (connected) {
                        auto *eject = new QPushButton(tr("Eject"), card);
                        connect(eject, &QPushButton::clicked, this, [this, drive, status, weakRefresh] {
                            setTaskFeedback(status);
                            startTask(QStringLiteral("network-optical-eject"), QStringLiteral("/usr/bin/pkexec"),
                                      {QStringLiteral("/usr/lib/eczos-network-optical/helper"), QStringLiteral("eject"),
                                       QStringLiteral("--device"), drive.value(QStringLiteral("device")).toString()},
                                      tr("Ejecting media…"), [status, weakRefresh](int result, const QByteArray &, const QByteArray &taskErrors) {
                                status->setText(result == 0 ? QObject::tr("Media ejected")
                                    : QString::fromUtf8(taskErrors).trimmed().section('\n', -1));
                                if (result == 0) {
                                    if (const auto action = weakRefresh.lock()) (*action)();
                                }
                            });
                        });
                        buttons->addWidget(eject);
                    }
                    buttons->addStretch(1);
                    cardLayout->addLayout(buttons);
                    if (connected) {
                        connect(autoConnect, &QCheckBox::toggled, this, [this, drive, status, weakRefresh](bool enabled) {
                            QStringList arguments{QStringLiteral("/usr/lib/eczos-network-optical/helper"),
                                                  QStringLiteral("set-auto"),
                                                  QStringLiteral("--host"), drive.value(QStringLiteral("address")).toString(),
                                                  QStringLiteral("--port"), QString::number(drive.value(QStringLiteral("port")).toInt(3260)),
                                                  QStringLiteral("--iqn"), drive.value(QStringLiteral("iqn")).toString()};
                            if (enabled) arguments << QStringLiteral("--enabled");
                            setTaskFeedback(status);
                            startTask(QStringLiteral("network-optical-auto"), QStringLiteral("/usr/bin/pkexec"), arguments,
                                      tr("Saving automatic connection…"),
                                      [status, weakRefresh](int result, const QByteArray &, const QByteArray &taskErrors) {
                                if (result == 0) {
                                    if (const auto action = weakRefresh.lock()) (*action)();
                                } else {
                                    const QString detail = QString::fromUtf8(taskErrors).trimmed();
                                    status->setText(detail.isEmpty() ? QObject::tr("The operation failed.") : detail.section('\n', -1));
                                }
                            });
                        });
                    }
                    connect(primary, &QPushButton::clicked, this, [this, drive, connected, autoConnect, status, weakRefresh] {
                        QStringList arguments{QStringLiteral("/usr/lib/eczos-network-optical/helper"),
                                              connected ? QStringLiteral("disconnect") : QStringLiteral("connect"),
                                              QStringLiteral("--host"), drive.value(QStringLiteral("address")).toString(),
                                              QStringLiteral("--port"), QString::number(drive.value(QStringLiteral("port")).toInt(3260)),
                                              QStringLiteral("--iqn"), drive.value(QStringLiteral("iqn")).toString()};
                        if (!connected && autoConnect->isChecked()) {
                            arguments << QStringLiteral("--auto");
                        }
                        setTaskFeedback(status);
                        startTask(QStringLiteral("network-optical-connect"), QStringLiteral("/usr/bin/pkexec"), arguments,
                                  connected ? tr("Disconnecting safely…") : tr("Connecting…"),
                                  [status, weakRefresh](int result, const QByteArray &, const QByteArray &taskErrors) {
                            if (result == 0) {
                                if (const auto action = weakRefresh.lock()) (*action)();
                            } else {
                                const QString detail = QString::fromUtf8(taskErrors).trimmed();
                                status->setText(detail.isEmpty() ? QObject::tr("The operation failed.") : detail.section('\n', -1));
                            }
                        });
                    });
                    networkLayout->addWidget(card);
                }
                if (network.isEmpty()) {
                    auto *empty = new QLabel(tr("No shared ECZOS optical drives are currently visible on the local network."), page);
                    empty->setAlignment(Qt::AlignCenter);
                    empty->setMinimumHeight(120);
                    networkLayout->addWidget(empty);
                }
                networkLayout->addStretch(1);
                status->setText(tr("Lists updated"));
            });
        };
        connect(refresh, &QPushButton::clicked, this, [weakRefresh] {
            if (const auto action = weakRefresh.lock()) (*action)();
        });
        auto *timer = new QTimer(page);
        timer->setInterval(5000);
        connect(timer, &QTimer::timeout, page, [weakRefresh] {
            if (const auto action = weakRefresh.lock()) (*action)();
        });
        timer->start();
        setCustomContent(page, tr("Network optical drives"),
                         tr("Use physical CD, DVD and Blu-ray drives from another ECZOS computer as normal local devices."));
        (*refreshData)();
    }

    void showNetworkSharesPage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        if (!QFileInfo::exists(QStringLiteral("/usr/bin/eczos-network-shares"))) {
            auto *missing = new QLabel(tr("The optional network-share component is not installed."), page);
            missing->setAlignment(Qt::AlignCenter);
            layout->addWidget(missing);
            layout->addStretch(1);
            setCustomContent(page, tr("Network shares"), tr("Open shared folders and servers"));
            return;
        }
        auto *summary = new QLabel(tr("Add SMB, NFS, WebDAV or SFTP locations. Passwords are requested and stored by KDE Wallet, never by ECZOS."), page);
        summary->setWordWrap(true);
        layout->addWidget(summary);
        auto *actions = new QHBoxLayout;
        auto *add = new QPushButton(QIcon::fromTheme(QStringLiteral("list-add")), tr("Add network location"), page);
        auto *discover = new QPushButton(QIcon::fromTheme(QStringLiteral("network-connect")), tr("Find on local network"), page);
        auto *refresh = new QPushButton(QIcon::fromTheme(QStringLiteral("view-refresh")), tr("Refresh"), page);
        actions->addWidget(add); actions->addWidget(discover); actions->addStretch(1); actions->addWidget(refresh);
        layout->addLayout(actions);
        auto *cards = new QVBoxLayout;
        layout->addLayout(cards);
        auto *status = new QLabel(page); status->setWordWrap(true); layout->addWidget(status); layout->addStretch(1);

        auto refreshData = std::make_shared<std::function<void()>>();
        std::weak_ptr<std::function<void()>> weakRefresh = refreshData;
        *refreshData = [this, page, cards, status, weakRefresh] {
            while (QLayoutItem *item = cards->takeAt(0)) {
                delete item->widget();
                delete item;
            }
            setTaskFeedback(status);
            startTask(QStringLiteral("network-shares-list"), QStringLiteral("/usr/bin/eczos-network-shares"),
                      {QStringLiteral("list"), QStringLiteral("--json")}, tr("Loading network locations…"),
                      [this, page, cards, status, weakRefresh](int code, const QByteArray &output, const QByteArray &errors) {
                          const QJsonObject data = QJsonDocument::fromJson(output).object();
                          if (code != 0 || data.isEmpty()) {
                              status->setText(QString::fromUtf8(errors).trimmed().section('\n', -1));
                              return;
                          }
                          const QJsonArray shares = data.value(QStringLiteral("shares")).toArray();
                          for (const QJsonValue &value : shares) {
                              const QJsonObject share = value.toObject();
                              auto *card = new QGroupBox(share.value(QStringLiteral("name")).toString(), page);
                              auto *cardLayout = new QVBoxLayout(card);
                              auto *detail = new QLabel(tr("%1 · %2").arg(share.value(QStringLiteral("protocol")).toString(), share.value(QStringLiteral("url")).toString()), card);
                              detail->setWordWrap(true); cardLayout->addWidget(detail);
                              auto *buttons = new QHBoxLayout;
                              auto *open = new QPushButton(QIcon::fromTheme(QStringLiteral("folder-open")), tr("Open"), card);
                              auto *test = new QPushButton(QIcon::fromTheme(QStringLiteral("network-connect")), tr("Test connection"), card);
                              auto *remove = new QPushButton(QIcon::fromTheme(QStringLiteral("edit-delete")), tr("Remove"), card);
                              buttons->addWidget(open); buttons->addWidget(test); buttons->addStretch(1); buttons->addWidget(remove);
                              cardLayout->addLayout(buttons); cards->addWidget(card);
                              const QString id = share.value(QStringLiteral("id")).toString();
                              connect(open, &QPushButton::clicked, this, [this, id, status] {
                                  setTaskFeedback(status);
                                  startTask(QStringLiteral("network-share-open"), QStringLiteral("/usr/bin/eczos-network-shares"),
                                            {QStringLiteral("open"), id}, tr("Opening network location…"));
                              });
                              connect(test, &QPushButton::clicked, this, [this, id, status] {
                                  setTaskFeedback(status);
                                  startTask(QStringLiteral("network-share-test"), QStringLiteral("/usr/bin/eczos-network-shares"),
                                            {QStringLiteral("test"), id}, tr("Testing the connection…"),
                                            [status](int testCode, const QByteArray &testOutput, const QByteArray &testErrors) {
                                                status->setText(QString::fromUtf8(testCode == 0 ? testOutput : testErrors).trimmed().section('\n', -1));
                                            });
                              });
                              connect(remove, &QPushButton::clicked, this, [this, id, status, weakRefresh] {
                                  if (QMessageBox::question(this, tr("Remove network location?"), tr("Remove this location from ECZOS and the file manager? Stored credentials remain under your control in KDE Wallet.")) != QMessageBox::Yes) return;
                                  setTaskFeedback(status);
                                  startTask(QStringLiteral("network-share-remove"), QStringLiteral("/usr/bin/eczos-network-shares"),
                                            {QStringLiteral("remove"), id}, tr("Removing network location…"),
                                            [status, weakRefresh](int removeCode, const QByteArray &removeOutput, const QByteArray &removeErrors) {
                                                status->setText(QString::fromUtf8(removeCode == 0 ? removeOutput : removeErrors).trimmed().section('\n', -1));
                                                if (removeCode == 0) if (const auto action = weakRefresh.lock()) (*action)();
                                            });
                              });
                          }
                          if (shares.isEmpty()) {
                              auto *empty = new QLabel(tr("No managed network locations yet."), page);
                              empty->setAlignment(Qt::AlignCenter); cards->addWidget(empty);
                          }
                          const QJsonArray existing = data.value(QStringLiteral("existing")).toArray();
                          if (!existing.isEmpty()) {
                              auto *heading = new QLabel(tr("Already available in Dolphin"), page);
                              heading->setStyleSheet(QStringLiteral("font-weight: 600; margin-top: 8px;")); cards->addWidget(heading);
                              for (const QJsonValue &value : existing) {
                                  const QJsonObject location = value.toObject();
                                  auto *card = new QGroupBox(location.value(QStringLiteral("name")).toString(), page);
                                  auto *cardLayout = new QHBoxLayout(card);
                                  auto *detail = new QLabel(tr("%1 · %2").arg(location.value(QStringLiteral("protocol")).toString(), location.value(QStringLiteral("url")).toString()), card);
                                  detail->setWordWrap(true); cardLayout->addWidget(detail, 1);
                                  auto *open = new QPushButton(QIcon::fromTheme(QStringLiteral("folder-open")), tr("Open"), card);
                                  auto *test = new QPushButton(QIcon::fromTheme(QStringLiteral("network-connect")), tr("Test connection"), card);
                                  cardLayout->addWidget(open); cardLayout->addWidget(test); cards->addWidget(card);
                                  const QString url = location.value(QStringLiteral("url")).toString();
                                  connect(open, &QPushButton::clicked, this, [this, url, status] {
                                      setTaskFeedback(status);
                                      startTask(QStringLiteral("network-share-open-existing"), QStringLiteral("/usr/bin/eczos-network-shares"),
                                                {QStringLiteral("open-url"), QStringLiteral("--url"), url}, tr("Opening network location…"));
                                  });
                                  connect(test, &QPushButton::clicked, this, [this, url, status] {
                                      setTaskFeedback(status);
                                      startTask(QStringLiteral("network-share-test-existing"), QStringLiteral("/usr/bin/eczos-network-shares"),
                                                {QStringLiteral("test-url"), QStringLiteral("--url"), url}, tr("Testing the connection…"));
                                  });
                              }
                          }
                          const QJsonArray mounted = data.value(QStringLiteral("mounted")).toArray();
                          if (!mounted.isEmpty()) {
                              auto *heading = new QLabel(tr("Already mounted outside ECZOS"), page);
                              heading->setStyleSheet(QStringLiteral("font-weight: 600; margin-top: 8px;")); cards->addWidget(heading);
                              for (const QJsonValue &value : mounted) {
                                  const QJsonObject mount = value.toObject();
                                  auto *label = new QLabel(tr("%1 at %2 · %3").arg(mount.value(QStringLiteral("source")).toString(), mount.value(QStringLiteral("target")).toString(), mount.value(QStringLiteral("type")).toString()), page);
                                  label->setWordWrap(true); cards->addWidget(label);
                              }
                          }
                          status->setText(tr("Network locations updated"));
                      });
        };
        const auto addLocation = [this, status, weakRefresh](const QString &suggestedName, const QString &suggestedUrl) {
            QDialog dialog(this);
            dialog.setWindowTitle(tr("Add network location"));
            dialog.setMinimumWidth(520);
            auto *dialogLayout = new QVBoxLayout(&dialog);
            auto *form = new QFormLayout;
            auto *nameField = new QLineEdit(suggestedName, &dialog);
            auto *protocol = new QComboBox(&dialog);
            protocol->addItem(tr("SMB — Windows PC or NAS"), QStringLiteral("smb"));
            protocol->addItem(tr("SFTP — secure files over SSH"), QStringLiteral("sftp"));
            protocol->addItem(tr("NFS — Linux or Unix share"), QStringLiteral("nfs"));
            protocol->addItem(tr("WebDAV — web folder"), QStringLiteral("webdav"));
            protocol->addItem(tr("Secure WebDAV — encrypted web folder"), QStringLiteral("webdavs"));
            auto *server = new QLineEdit(&dialog);
            server->setPlaceholderText(tr("server name or IP address"));
            auto *path = new QLineEdit(&dialog);
            auto *user = new QLineEdit(&dialog);
            user->setPlaceholderText(tr("optional; password is requested by KDE Wallet"));
            auto *port = new QLineEdit(&dialog);
            port->setPlaceholderText(tr("automatic"));
            auto *help = new QLabel(&dialog);
            help->setWordWrap(true);
            help->setObjectName(QStringLiteral("pageDescription"));
            form->addRow(tr("Name shown in Dolphin"), nameField);
            form->addRow(tr("Protocol"), protocol);
            form->addRow(tr("Server"), server);
            form->addRow(tr("Shared folder or path"), path);
            form->addRow(tr("Username"), user);
            form->addRow(tr("Port"), port);
            dialogLayout->addLayout(form);
            dialogLayout->addWidget(help);
            auto *buttons = new QDialogButtonBox(QDialogButtonBox::Ok | QDialogButtonBox::Cancel, &dialog);
            dialogLayout->addWidget(buttons);
            connect(buttons, &QDialogButtonBox::accepted, &dialog, &QDialog::accept);
            connect(buttons, &QDialogButtonBox::rejected, &dialog, &QDialog::reject);

            const QUrl suggested(suggestedUrl);
            if (suggested.isValid() && !suggested.scheme().isEmpty()) {
                const int selected = protocol->findData(suggested.scheme().toLower());
                if (selected >= 0) protocol->setCurrentIndex(selected);
                server->setText(suggested.host());
                path->setText(suggested.path().mid(1));
                user->setText(suggested.userName());
                if (suggested.port() > 0) port->setText(QString::number(suggested.port()));
            }
            const auto updateProtocolHelp = [this, protocol, path, user, help] {
                const QString scheme = protocol->currentData().toString();
                user->setEnabled(scheme != QStringLiteral("nfs"));
                if (scheme == QStringLiteral("smb")) {
                    path->setPlaceholderText(tr("for example: Shared Documents"));
                    help->setText(tr("Use the share name shown by the Windows PC or NAS. Result: smb://server/Shared%20Documents"));
                } else if (scheme == QStringLiteral("sftp")) {
                    path->setPlaceholderText(tr("for example: home/name/files"));
                    help->setText(tr("SFTP uses an SSH account. KDE Wallet asks for and stores the password securely."));
                } else if (scheme == QStringLiteral("nfs")) {
                    path->setPlaceholderText(tr("for example: exports/shared"));
                    help->setText(tr("Enter the exported NFS path configured on the server."));
                } else {
                    path->setPlaceholderText(tr("for example: remote.php/dav/files/name"));
                    help->setText(tr("Enter the WebDAV path supplied by the server or cloud provider."));
                }
            };
            connect(protocol, &QComboBox::currentIndexChanged, &dialog, [updateProtocolHelp] { updateProtocolHelp(); });
            updateProtocolHelp();
            QString name;
            QString url;
            while (url.isEmpty()) {
                if (dialog.exec() != QDialog::Accepted) return;
                name = nameField->text().trimmed();
                const QString host = server->text().trimmed();
                QString remotePath = path->text().trimmed();
                while (remotePath.startsWith(QLatin1Char('/'))) remotePath.remove(0, 1);
                bool portOkay = true;
                const int portNumber = port->text().trimmed().isEmpty() ? -1 : port->text().trimmed().toInt(&portOkay);
                if (name.isEmpty() || host.isEmpty() || remotePath.isEmpty() || !portOkay || portNumber == 0 || portNumber > 65535) {
                    QMessageBox::warning(this, tr("Incomplete network location"),
                        tr("Enter a display name, server and shared folder or path. The optional port must be between 1 and 65535."));
                    continue;
                }
                QUrl address;
                address.setScheme(protocol->currentData().toString());
                address.setHost(host);
                if (portNumber > 0) address.setPort(portNumber);
                if (user->isEnabled() && !user->text().trimmed().isEmpty()) address.setUserName(user->text().trimmed());
                address.setPath(QStringLiteral("/") + remotePath);
                url = address.toString(QUrl::FullyEncoded);
            }
            setTaskFeedback(status);
            startTask(QStringLiteral("network-share-add"), QStringLiteral("/usr/bin/eczos-network-shares"),
                      {QStringLiteral("add"), QStringLiteral("--name"), name, QStringLiteral("--url"), url}, tr("Adding network location…"),
                      [status, weakRefresh](int addCode, const QByteArray &, const QByteArray &addErrors) {
                          if (addCode != 0) status->setText(QString::fromUtf8(addErrors).trimmed().section('\n', -1));
                          else if (const auto action = weakRefresh.lock()) (*action)();
                      });
        };
        connect(add, &QPushButton::clicked, this, [addLocation] {
            addLocation(QString(), QString());
        });
        connect(discover, &QPushButton::clicked, this, [this, status, addLocation] {
            setTaskFeedback(status);
            startTask(QStringLiteral("network-share-discover"), QStringLiteral("/usr/bin/eczos-network-shares"),
                      {QStringLiteral("discover"), QStringLiteral("--json")}, tr("Searching the local network…"),
                      [this, status, addLocation](int code, const QByteArray &output, const QByteArray &errors) {
                          const QJsonArray services = QJsonDocument::fromJson(output).object().value(QStringLiteral("services")).toArray();
                          if (code != 0 || services.isEmpty()) {
                              status->setText(code == 0 ? tr("No supported network services were found automatically. You can still add an address manually.") : QString::fromUtf8(errors).trimmed().section('\n', -1));
                              return;
                          }
                          QStringList labels;
                          for (const QJsonValue &value : services) {
                              const QJsonObject service = value.toObject();
                              labels << tr("%1 · %2 · %3").arg(service.value(QStringLiteral("name")).toString(), service.value(QStringLiteral("protocol")).toString(), service.value(QStringLiteral("url")).toString());
                          }
                          bool okay = false;
                          const QString selected = QInputDialog::getItem(this, tr("Network services found"), tr("Choose a location"), labels, 0, false, &okay);
                          if (!okay) return;
                          const int index = labels.indexOf(selected);
                          if (index >= 0) {
                              const QJsonObject service = services.at(index).toObject();
                              addLocation(service.value(QStringLiteral("name")).toString(), service.value(QStringLiteral("url")).toString());
                          }
                      });
        });
        connect(refresh, &QPushButton::clicked, this, [refreshData] { (*refreshData)(); });
        setCustomContent(page, tr("Network shares"), tr("Secure access to shared folders through KDE Wallet and on-demand reconnect."));
        (*refreshData)();
    }

    void showHardwarePage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        if (!QFileInfo::exists(QStringLiteral("/usr/bin/eczos-hardware"))) {
            auto *missing = new QLabel(tr("The optional ECZOS hardware module is not installed."), page);
            missing->setAlignment(Qt::AlignCenter); layout->addWidget(missing); layout->addStretch(1);
            setCustomContent(page, tr("Hardware profile"), tr("Memory, storage and performance profile")); return;
        }
        auto *hardware = new QLabel(tr("Detecting hardware…"), page); hardware->setWordWrap(true);
        auto *memory = new QLabel(page); memory->setWordWrap(true);
        hardware->setVisible(m_advancedMode);
        memory->setVisible(m_advancedMode);
        auto *recommendation = new QLabel(page); recommendation->setWordWrap(true);
        auto *diagnostics = new QLabel(page); diagnostics->setWordWrap(true);
        layout->addWidget(hardware); layout->addWidget(memory); layout->addWidget(recommendation); layout->addWidget(diagnostics);
        auto *issueActions = new QVBoxLayout;
        layout->addLayout(issueActions);
        auto *choice = new QComboBox(page);
        choice->addItem(tr("Lightweight — for limited memory or older processors"), QStringLiteral("lightweight"));
        choice->addItem(tr("Standard — balanced everyday use"), QStringLiteral("standard"));
        choice->addItem(tr("Performance — powerful workstation"), QStringLiteral("performance"));
        choice->addItem(tr("Gaming — prioritise games and compressed memory"), QStringLiteral("gaming"));
        choice->addItem(tr("Enterprise — stable managed defaults"), QStringLiteral("enterprise"));
        auto *apply = new QPushButton(QIcon::fromTheme(QStringLiteral("dialog-ok-apply")), tr("Apply profile"), page);
        auto *row = new QHBoxLayout; row->addWidget(choice, 1); row->addWidget(apply); layout->addLayout(row);
        auto *explanation = new QLabel(tr("Profiles tune zram and memory behaviour. Existing disk swap is preserved. ECZOS does not change CPU, GPU or battery controls without showing a separate setting."), page);
        explanation->setWordWrap(true); layout->addWidget(explanation);
        auto *status = new QLabel(page); status->setWordWrap(true); layout->addWidget(status); layout->addStretch(1);
        setTaskFeedback(status);
        startTask(QStringLiteral("hardware-status"), QStringLiteral("/usr/bin/eczos-hardware"), {QStringLiteral("status"), QStringLiteral("--json")}, tr("Detecting hardware…"),
                  [this, page, hardware, memory, recommendation, diagnostics, issueActions, choice, status](int code, const QByteArray &output, const QByteArray &errors) {
                      const QJsonObject data = QJsonDocument::fromJson(output).object();
                      if (code != 0 || data.isEmpty()) { status->setText(QString::fromUtf8(errors).trimmed().section('\n', -1)); return; }
                      while (QLayoutItem *item = issueActions->takeAt(0)) {
                          if (item->layout()) delete item->layout();
                          delete item->widget();
                          delete item;
                      }
                      const QJsonObject cpu = data.value(QStringLiteral("cpu")).toObject();
                      const QJsonObject mem = data.value(QStringLiteral("memory")).toObject();
                      const QJsonObject storage = data.value(QStringLiteral("systemStorage")).toObject();
                      const QString graphics = data.value(QStringLiteral("graphics")).toArray().toVariantList().isEmpty()
                          ? tr("No graphics adapter identified") : data.value(QStringLiteral("graphics")).toArray().first().toString();
                      hardware->setText(tr("%1 · %2 logical processors\nGraphics: %3\nSystem storage: %4")
                          .arg(cpu.value(QStringLiteral("model")).toString()).arg(cpu.value(QStringLiteral("logicalProcessors")).toInt())
                          .arg(graphics, storage.value(QStringLiteral("source")).toString()));
                      memory->setText(tr("Memory: %1 GiB · Swap: %2 GiB · zram: %3 · Swappiness: %4")
                          .arg(mem.value(QStringLiteral("totalKiB")).toInteger() / 1048576.0, 0, 'f', 1)
                          .arg(mem.value(QStringLiteral("swapKiB")).toInteger() / 1048576.0, 0, 'f', 1)
                          .arg(mem.value(QStringLiteral("zramActive")).toBool() ? tr("active") : tr("inactive"))
                          .arg(mem.value(QStringLiteral("swappiness")).toInt()));
                      const QString recommended = data.value(QStringLiteral("recommendedProfile")).toString();
                      const int recommendedIndex = choice->findData(recommended); if (recommendedIndex >= 0) choice->setCurrentIndex(recommendedIndex);
                      recommendation->setText(tr("Recommended profile: %1. Current profile: %2.")
                          .arg(recommended, data.value(QStringLiteral("currentProfile")).toString(tr("not selected"))));
                      const QJsonArray problems = data.value(QStringLiteral("issues")).toArray();
                      QStringList issueLines;
                      for (const QJsonValue &value : problems) {
                          const QJsonObject problem = value.toObject();
                          const QString id = problem.value(QStringLiteral("id")).toString();
                          QString detail = problem.value(QStringLiteral("summary")).toString();
                          if (id == QStringLiteral("graphics-missing")) detail = tr("No graphics adapter was detected.");
                          else if (id == QStringLiteral("graphics-driver")) detail = tr("A graphics adapter has no active kernel driver.");
                          else if (id == QStringLiteral("graphics-renderer")) detail = tr("Graphics are using slow software rendering.");
                          else if (id == QStringLiteral("storage-space")) detail = tr("The system disk has less than 10% free space.");
                          else if (id == QStringLiteral("network-offline")) detail = tr("No active network connection was detected.");
                          else if (id == QStringLiteral("bluetooth-blocked")) detail = tr("Bluetooth hardware is present but blocked.");
                          else if (id == QStringLiteral("bluetooth-service")) detail = tr("Bluetooth hardware is present but its service is not running.");
                          else if (id == QStringLiteral("zram-inactive")) detail = tr("A hardware profile is selected, but zram is not active.");
                          else if (id == QStringLiteral("failed-services")) detail = tr("%1 system service(s) failed.").arg(data.value(QStringLiteral("failedUnits")).toInt());
                          issueLines << QStringLiteral("• ") + detail;
                          const QString repair = problem.value(QStringLiteral("repair")).toString();
                          if (!repair.isEmpty()) {
                              auto *repairRow = new QHBoxLayout;
                              auto *repairLabel = new QLabel(detail, page);
                              repairLabel->setWordWrap(true);
                              auto *repairButton = new QPushButton(QIcon::fromTheme(QStringLiteral("tools-wizard")), tr("Repair"), page);
                              repairRow->addWidget(repairLabel, 1);
                              repairRow->addWidget(repairButton);
                              issueActions->addLayout(repairRow);
                              connect(repairButton, &QPushButton::clicked, this, [this, repair, status] {
                                  setTaskFeedback(status);
                                  startTask(QStringLiteral("hardware-repair"), QStringLiteral("/usr/bin/eczos-hardware"),
                                            {QStringLiteral("repair"), repair}, tr("Repairing the detected problem…"),
                                            [this, status](int repairCode, const QByteArray &repairOutput, const QByteArray &repairErrors) {
                                                status->setText(QString::fromUtf8(repairCode == 0 ? repairOutput : repairErrors).trimmed().section('\n', -1));
                                                if (repairCode == 0) QTimer::singleShot(500, this, [this] { showHardwarePage(); });
                                            });
                              });
                          }
                      }
                      diagnostics->setText(issueLines.isEmpty() ? tr("No hardware problems detected")
                                                                : tr("Hardware needs attention:\n%1").arg(issueLines.join(QLatin1Char('\n'))));
                      diagnostics->setStyleSheet(issueLines.isEmpty() ? QStringLiteral("color: #15805f;") : QStringLiteral("color: #b36b00;"));
                      if (!issueLines.isEmpty() && issueActions->count() == 0) {
                          auto *manual = new QLabel(tr("No automatic change is offered because these findings require a hardware, storage, network or driver choice."), page);
                          manual->setWordWrap(true);
                          issueActions->addWidget(manual);
                      }
                      status->setText(tr("Hardware detection complete"));
                  });
        connect(apply, &QPushButton::clicked, this, [this, choice, status] {
            if (QMessageBox::question(this, tr("Apply hardware profile?"),
                    tr("Apply the selected memory profile? Existing swap remains available.")) != QMessageBox::Yes) return;
            setTaskFeedback(status);
            startTask(QStringLiteral("hardware-apply"), QStringLiteral("/usr/bin/eczos-hardware"),
                      {QStringLiteral("apply"), choice->currentData().toString()}, tr("Applying hardware profile…"),
                      [this, status](int code, const QByteArray &output, const QByteArray &errors) {
                          status->setText(QString::fromUtf8(code == 0 ? output : errors).trimmed().section('\n', -1));
                          if (code == 0) QTimer::singleShot(300, this, [this] { showHardwarePage(); });
                      });
        });
        setCustomContent(page, tr("Hardware profile"), tr("Choose safe memory behaviour based on this computer's actual hardware."));
    }

    void showBootPage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        if (!QFileInfo::exists(QStringLiteral("/usr/bin/eczos-boot"))) {
            auto *missing = new QLabel(tr("The optional boot-management component is not installed."), page);
            missing->setAlignment(Qt::AlignCenter); layout->addWidget(missing); layout->addStretch(1);
            setCustomContent(page, tr("Startup and operating systems"), tr("Detect systems and manage the boot menu safely")); return;
        }
        auto *policy = new QLabel(tr("ECZOS can detect other operating systems and refresh the GRUB menu. It never changes EFI boot order or reinstalls a bootloader from this page."), page);
        policy->setWordWrap(true); layout->addWidget(policy);
        auto *platform = new QLabel(tr("Reading boot information…"), page); platform->setWordWrap(true); layout->addWidget(platform);
        platform->setVisible(m_advancedMode);
        auto *systems = new QVBoxLayout; layout->addLayout(systems);
        auto *actions = new QHBoxLayout;
        auto *scan = new QPushButton(QIcon::fromTheme(QStringLiteral("view-refresh")), tr("Scan again"), page);
        auto *update = new QPushButton(QIcon::fromTheme(QStringLiteral("system-reboot")), tr("Update boot menu safely"), page);
        actions->addWidget(scan); actions->addWidget(update); actions->addStretch(1); layout->addLayout(actions);
        auto *status = new QLabel(page); status->setWordWrap(true); layout->addWidget(status); layout->addStretch(1);

        const auto load = [this, page, platform, systems, update, status] {
            while (QLayoutItem *item = systems->takeAt(0)) { delete item->widget(); delete item; }
            setTaskFeedback(status);
            startTask(QStringLiteral("boot-status"), QStringLiteral("/usr/bin/eczos-boot"),
                      {QStringLiteral("status"), QStringLiteral("--json")}, tr("Reading boot information…"),
                      [this, page, platform, systems, update, status](int code, const QByteArray &output, const QByteArray &errors) {
                          const QJsonObject data = QJsonDocument::fromJson(output).object();
                          if (code != 0 || data.isEmpty()) { status->setText(QString::fromUtf8(errors).trimmed().section('\n', -1)); return; }
                          const QString mode = data.value(QStringLiteral("mode")).toString();
                          platform->setText(tr("Boot mode: %1 · Bootloader: %2 · Detection of other systems: %3")
                              .arg(mode.toUpper(), data.value(QStringLiteral("bootloader")).toString(),
                                   data.value(QStringLiteral("osProberEnabled")).toBool() ? tr("enabled") : tr("disabled")));
                          const QJsonArray entries = data.value(QStringLiteral("operatingSystems")).toArray();
                          bool allValid = true;
                          for (const QJsonValue &value : entries) {
                              const QJsonObject entry = value.toObject();
                              const bool valid = entry.value(QStringLiteral("validated")).toBool(); allValid &= valid;
                              systems->addWidget(statusCard(entry.value(QStringLiteral("label")).toString(tr("Unknown operating system")),
                                  m_advancedMode
                                      ? tr("%1 · %2 · %3").arg(entry.value(QStringLiteral("device")).toString(), entry.value(QStringLiteral("method")).toString(),
                                            valid ? tr("boot files verified") : tr("boot files could not be verified"))
                                      : (valid ? tr("Ready to start") : tr("Boot files could not be verified")), valid, page));
                          }
                          if (entries.isEmpty()) {
                              auto *none = new QLabel(tr("No other operating systems were detected."), page);
                              none->setAlignment(Qt::AlignCenter); systems->addWidget(none);
                          }
                          update->setEnabled(data.value(QStringLiteral("available")).toBool() && data.value(QStringLiteral("osProberEnabled")).toBool() && allValid);
                          status->setText(data.value(QStringLiteral("stale")).toBool() ? tr("Run a new scan to inspect this computer.") : tr("Boot scan complete"));
                      });
        };
        connect(scan, &QPushButton::clicked, this, [this, status] {
            setTaskFeedback(status);
            startTask(QStringLiteral("boot-scan"), QStringLiteral("/usr/bin/eczos-boot"), {QStringLiteral("scan")}, tr("Scanning disks and boot files…"),
                      [this, status](int code, const QByteArray &, const QByteArray &errors) {
                          if (code == 0) QTimer::singleShot(300, this, [this] { showBootPage(); });
                          else status->setText(QString::fromUtf8(errors).trimmed().section('\n', -1));
                      });
        });
        connect(update, &QPushButton::clicked, this, [this, status] {
            if (QMessageBox::question(this, tr("Update boot menu?"),
                tr("ECZOS will create a backup, generate a new GRUB menu, validate it and restore the previous menu automatically if verification fails. Continue?")) != QMessageBox::Yes) return;
            setTaskFeedback(status);
            startTask(QStringLiteral("boot-update"), QStringLiteral("/usr/bin/eczos-boot"), {QStringLiteral("update-menu")}, tr("Generating and verifying the boot menu…"),
                      [status](int code, const QByteArray &output, const QByteArray &errors) {
                          status->setText(QString::fromUtf8(code == 0 ? output : errors).trimmed().section('\n', -1));
                      });
        });
        setCustomContent(page, tr("Startup and operating systems"), tr("Validated multiboot detection with transactional GRUB updates."));
        load();
    }

    void showTimePage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        auto *grid = new QGridLayout;
        auto *clock = new QLabel(page);
        auto *service = new QLabel(page);
        auto *zone = new QLabel(page);
        auto *rtc = new QLabel(page);
        for (QLabel *label : {clock, service, zone, rtc}) label->setWordWrap(true);
        const auto addCard = [this, page, grid](int row, int column, const QString &title, QLabel *value) {
            auto *card = statusCard(title, tr("Checking…"), true, page);
            auto *old = card->findChildren<QLabel *>().last();
            card->layout()->replaceWidget(old, value);
            old->deleteLater();
            grid->addWidget(card, row, column);
        };
        addCard(0, 0, tr("Clock status"), clock);
        addCard(0, 1, tr("Network time service"), service);
        addCard(1, 0, tr("Timezone"), zone);
        addCard(1, 1, tr("Hardware clock"), rtc);
        layout->addLayout(grid);
        auto *notice = new QLabel(page);
        notice->setWordWrap(true);
        layout->addWidget(notice);
        auto *actions = new QHBoxLayout;
        auto *repair = new QPushButton(QIcon::fromTheme(QStringLiteral("tools-wizard")), tr("Repair automatic time"), page);
        auto *configure = new QPushButton(QIcon::fromTheme(QStringLiteral("preferences-system-time")), tr("Change date, time or timezone"), page);
        actions->addWidget(repair);
        actions->addWidget(configure);
        actions->addStretch(1);
        layout->addLayout(actions);
        auto *status = new QLabel(page);
        status->setWordWrap(true);
        layout->addWidget(status);
        layout->addStretch(1);

        setTaskFeedback(status);
        startTask(QStringLiteral("time-status"), QStringLiteral("/usr/bin/eczos-time"), {QStringLiteral("status"), QStringLiteral("--json")}, tr("Checking date and time…"),
                  [this, clock, service, zone, rtc, notice, repair, status](int code, const QByteArray &output, const QByteArray &errors) {
                      const QJsonObject data = QJsonDocument::fromJson(output).object();
                      if (code != 0 || data.isEmpty()) {
                          status->setText(QString::fromUtf8(errors).trimmed().section('\n', -1));
                          repair->setEnabled(false);
                          return;
                      }
                      const bool synchronized = data.value(QStringLiteral("synchronized")).toBool();
                      clock->setText(synchronized ? tr("Automatically synchronized") : tr("Not synchronized"));
                      service->setText(tr("%1 · %2").arg(data.value(QStringLiteral("provider")).toString(),
                                                         data.value(QStringLiteral("providerActive")).toBool() ? tr("running") : tr("stopped")));
                      zone->setText(data.value(QStringLiteral("timezone")).toString());
                      const bool localRtc = data.value(QStringLiteral("localRtc")).toBool();
                      rtc->setText(localRtc ? tr("Local time (kept for compatibility)") : QStringLiteral("UTC"));
                      notice->setText(localRtc
                          ? tr("This computer stores local time in its hardware clock, which may be intentional for another operating system. Automatic repair will not change it.")
                          : tr("The hardware clock uses the recommended UTC mode."));
                      repair->setEnabled(!synchronized || !data.value(QStringLiteral("ntpEnabled")).toBool()
                                         || !data.value(QStringLiteral("providerActive")).toBool());
                      status->setText(data.value(QStringLiteral("summary")).toString());
                  });
        connect(repair, &QPushButton::clicked, this, [this, status] {
            setTaskFeedback(status);
            startTask(QStringLiteral("time-repair"), QStringLiteral("/usr/bin/eczos-time"), {QStringLiteral("repair")}, tr("Repairing automatic time…"),
                      [this, status](int code, const QByteArray &output, const QByteArray &errors) {
                          const QString result = QString::fromUtf8(code == 0 ? output : errors).trimmed();
                          status->setText(result.section('\n', -1));
                          if (code == 0) QTimer::singleShot(300, this, [this] { showTimePage(); });
                      });
        });
        connect(configure, &QPushButton::clicked, this, [this] { openEntry(QStringLiteral("kcm_clock")); });
        setCustomContent(page, tr("Date and time"), tr("Keep the system clock accurate while preserving multi-boot compatibility."));
    }

    void showRemoteInputPage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        auto *summary = new QLabel(tr("ECZOS can keep Deskflow, Synergy or Barrier available without starting duplicate background services."), page);
        summary->setWordWrap(true);
        layout->addWidget(summary);

        auto *grid = new QGridLayout;
        auto *provider = new QLabel(page);
        auto *service = new QLabel(page);
        auto *connection = new QLabel(page);
        auto *startup = new QLabel(page);
        provider->setWordWrap(true);
        service->setWordWrap(true);
        connection->setWordWrap(true);
        startup->setWordWrap(true);
        grid->addWidget(statusCard(tr("Sharing application"), tr("Checking…"), true, page), 0, 0);
        grid->addWidget(statusCard(tr("Managed startup"), tr("Checking…"), true, page), 0, 1);
        auto *providerCard = qobject_cast<QGroupBox *>(grid->itemAtPosition(0, 0)->widget());
        auto *serviceCard = qobject_cast<QGroupBox *>(grid->itemAtPosition(0, 1)->widget());
        auto *oldProvider = providerCard->findChildren<QLabel *>().last();
        auto *oldService = serviceCard->findChildren<QLabel *>().last();
        providerCard->layout()->replaceWidget(oldProvider, provider);
        serviceCard->layout()->replaceWidget(oldService, service);
        oldProvider->deleteLater();
        oldService->deleteLater();
        grid->addWidget(statusCard(tr("Connection"), tr("Checking…"), true, page), 1, 0);
        grid->addWidget(statusCard(tr("Old startup methods"), tr("Checking…"), true, page), 1, 1);
        auto *connectionCard = qobject_cast<QGroupBox *>(grid->itemAtPosition(1, 0)->widget());
        auto *startupCard = qobject_cast<QGroupBox *>(grid->itemAtPosition(1, 1)->widget());
        auto *oldConnection = connectionCard->findChildren<QLabel *>().last();
        auto *oldStartup = startupCard->findChildren<QLabel *>().last();
        connectionCard->layout()->replaceWidget(oldConnection, connection);
        startupCard->layout()->replaceWidget(oldStartup, startup);
        oldConnection->deleteLater();
        oldStartup->deleteLater();
        layout->addLayout(grid);

        auto *actions = new QHBoxLayout;
        auto *adopt = new QPushButton(QIcon::fromTheme(QStringLiteral("emblem-synchronized")), tr("Manage automatically"), page);
        auto *restart = new QPushButton(QIcon::fromTheme(QStringLiteral("view-refresh")), tr("Start or reconnect"), page);
        auto *stop = new QPushButton(QIcon::fromTheme(QStringLiteral("process-stop")), tr("Release local input"), page);
        auto *disable = new QPushButton(tr("Disable automatic startup"), page);
        actions->addWidget(adopt);
        actions->addWidget(restart);
        actions->addWidget(stop);
        actions->addWidget(disable);
        actions->addStretch(1);
        layout->addLayout(actions);
        auto *providerSettings = new QPushButton(QIcon::fromTheme(QStringLiteral("configure")), tr("Open sharing application settings"), page);
        layout->addWidget(providerSettings, 0, Qt::AlignLeft);
        auto *hint = new QLabel(tr("If input ever appears stuck, choose ‘Release local input’. The same emergency action is available from the application menu."), page);
        hint->setWordWrap(true);
        auto *status = new QLabel(page);
        status->setWordWrap(true);
        layout->addWidget(hint);
        layout->addWidget(status);
        layout->addStretch(1);

        auto refreshData = std::make_shared<std::function<void()>>();
        std::weak_ptr<std::function<void()>> weakRefresh = refreshData;
        *refreshData = [this, provider, service, connection, startup, adopt, restart, stop, disable, providerSettings, status] {
            setTaskFeedback(status);
            startTask(QStringLiteral("remote-input-status"), QStringLiteral("/usr/bin/eczos-remote-input"), {QStringLiteral("status"), QStringLiteral("--json")}, tr("Checking keyboard and mouse sharing…"),
                      [provider, service, connection, startup, adopt, restart, stop, disable, providerSettings, status](int code, const QByteArray &output, const QByteArray &errors) {
                          const QJsonObject data = QJsonDocument::fromJson(output).object();
                          if (code != 0 || data.isEmpty()) {
                              status->setText(QString::fromUtf8(errors).trimmed().section('\n', -1));
                              return;
                          }
                          const QString providerName = data.value(QStringLiteral("provider")).toString();
                          const bool installed = providerName != QStringLiteral("none");
                          const bool managed = data.value(QStringLiteral("managed")).toBool();
                          const bool active = data.value(QStringLiteral("active")).toBool();
                          const bool duplicate = data.value(QStringLiteral("duplicate")).toBool();
                          const int legacy = data.value(QStringLiteral("legacyMechanisms")).toInt();
                          const QString host = data.value(QStringLiteral("remoteHost")).toString();
                          provider->setText(installed ? tr("%1 detected").arg(providerName) : tr("Not installed"));
                          service->setText(managed ? (active ? tr("Running and starts automatically") : tr("Enabled, currently stopped"))
                                                   : tr("Not managed by ECZOS yet"));
                          connection->setText(host.isEmpty() ? tr("No remote computer configured")
                                                             : tr("Remote computer: %1 · %2 session").arg(host, data.value(QStringLiteral("session")).toString()));
                          startup->setText(duplicate ? tr("Conflicting startup methods found")
                                                     : legacy > 0 ? tr("%1 existing startup method detected").arg(legacy)
                                                                  : tr("No conflicting startup methods"));
                          adopt->setEnabled(installed && (!managed || legacy > 0));
                          restart->setEnabled(installed && managed);
                          stop->setEnabled(data.value(QStringLiteral("processes")).toInt() > 0 || active);
                          disable->setEnabled(managed);
                          providerSettings->setEnabled(installed);
                          status->setText(tr("Status updated"));
                      });
        };
        const auto action = [this, status, weakRefresh](const QString &operation, const QString &message) {
            setTaskFeedback(status);
            startTask(QStringLiteral("remote-input-") + operation, QStringLiteral("/usr/bin/eczos-remote-input"), {operation}, message,
                      [status, weakRefresh](int code, const QByteArray &output, const QByteArray &errors) {
                          if (code != 0) {
                              status->setText(QString::fromUtf8(errors).trimmed().section('\n', -1));
                              return;
                          }
                          status->setText(QString::fromUtf8(output).trimmed());
                          if (const auto refresh = weakRefresh.lock()) {
                              QTimer::singleShot(250, [refresh] { (*refresh)(); });
                          }
                      });
        };
        connect(adopt, &QPushButton::clicked, this, [this, action] { action(QStringLiteral("adopt"), tr("Taking over existing startup safely…")); });
        connect(restart, &QPushButton::clicked, this, [this, action] { action(QStringLiteral("restart"), tr("Reconnecting…")); });
        connect(stop, &QPushButton::clicked, this, [this, action] { action(QStringLiteral("emergency-stop"), tr("Releasing local input…")); });
        connect(disable, &QPushButton::clicked, this, [this, action] { action(QStringLiteral("disable"), tr("Disabling automatic startup…")); });
        connect(providerSettings, &QPushButton::clicked, this, [] {
            QProcess::startDetached(QStringLiteral("/usr/bin/eczos-remote-input"), {QStringLiteral("configure")});
        });
        setCustomContent(page, tr("Keyboard and mouse sharing"), tr("Reliable shared input with automatic reconnect and an immediate emergency stop."));
        (*refreshData)();
    }

    void showDiagnosticsPage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        auto *grid = new QGridLayout;
        layout->addLayout(grid);
        auto *status = new QLabel(tr("Checking the computer…"), page);
        status->setWordWrap(true);
        auto *refresh = new QPushButton(tr("Check again"), page);
        layout->addWidget(status);
        layout->addWidget(refresh, 0, Qt::AlignLeft);
        layout->addStretch(1);
        const auto run = [this, grid, status] {
            while (QLayoutItem *item = grid->takeAt(0)) {
                delete item->widget();
                delete item;
            }
            setTaskFeedback(status);
            startTask(QStringLiteral("diagnostics"), QStringLiteral("/usr/bin/eczos-doctor"), {QStringLiteral("--json")}, tr("Checking the computer…"),
                      [this, grid, status](int code, const QByteArray &output, const QByteArray &errors) {
                          const QJsonObject data = QJsonDocument::fromJson(output).object();
                          if (code != 0 || data.isEmpty()) {
                              status->setText(QString::fromUtf8(errors).trimmed().section('\n', -1));
                              return;
                          }
                          const auto add = [this, grid](int index, const QString &title, bool okay, const QString &detail) {
                              grid->addWidget(statusCard(title, detail, okay, grid->parentWidget()), index / 2, index % 2);
                          };
                          const QJsonObject apps = data.value(QStringLiteral("applications")).toObject();
                          const QJsonObject devices = data.value(QStringLiteral("devices")).toObject();
                          const QJsonObject time = data.value(QStringLiteral("time")).toObject();
                          const QJsonObject memory = data.value(QStringLiteral("memory")).toObject();
                          const QJsonObject input = data.value(QStringLiteral("inputSharing")).toObject();
                          const QJsonObject remote = data.value(QStringLiteral("remoteSupport")).toObject();
                          add(0, tr("Windows apps"), data.value(QStringLiteral("windows")).toBool(), tr("Compatibility layer"));
                          add(1, tr("Gaming"), data.value(QStringLiteral("gaming")).toString() == QStringLiteral("ready"), data.value(QStringLiteral("gaming")).toString());
                          add(2, tr("Apps and Flatpak"), apps.value(QStringLiteral("discover")).toBool() && apps.value(QStringLiteral("flatpak")).toBool(), tr("Software management"));
                          add(3, tr("Backup"), data.value(QStringLiteral("backup")).toBool(), tr("Personal files"));
                          add(4, tr("Phone connection"), data.value(QStringLiteral("phone")).toBool(), QStringLiteral("KDE Connect"));
                          add(5, tr("Printers and scanners"), devices.value(QStringLiteral("printer")).toBool() && devices.value(QStringLiteral("scanner")).toBool(), tr("Device support"));
                          const int failed = data.value(QStringLiteral("failedUnits")).toInt();
                          add(6, tr("System services"), failed == 0, failed == 0 ? tr("No errors found") : tr("%1 service(s) need attention").arg(failed));
                          add(7, QStringLiteral("FreeOffice"), data.value(QStringLiteral("office")).toString() == QStringLiteral("installed"), data.value(QStringLiteral("office")).toString());
                          const bool clockOkay = time.value(QStringLiteral("ntpEnabled")).toBool()
                              && time.value(QStringLiteral("synchronized")).toBool();
                          add(8, tr("Date and time"), clockOkay,
                              clockOkay ? tr("Automatically synchronized · %1").arg(time.value(QStringLiteral("timezone")).toString())
                                        : tr("Automatic time needs attention"));
                          add(9, tr("Memory and swap"), memory.value(QStringLiteral("totalKiB")).toInteger() > 0,
                              tr("%1 GiB memory · %2 GiB swap%3")
                                  .arg(memory.value(QStringLiteral("totalKiB")).toInteger() / 1048576.0, 0, 'f', 1)
                                  .arg(memory.value(QStringLiteral("swapKiB")).toInteger() / 1048576.0, 0, 'f', 1)
                                  .arg(memory.value(QStringLiteral("zram")).toBool() ? tr(" · zram active") : QString()));
                          const QString inputProvider = input.value(QStringLiteral("provider")).toString();
                          const bool inputOkay = !input.value(QStringLiteral("duplicate")).toBool();
                          add(10, tr("Keyboard and mouse sharing"), inputOkay,
                              input.value(QStringLiteral("duplicate")).toBool()
                                  ? tr("Multiple input-sharing processes are active")
                                  : inputProvider == QStringLiteral("none") ? tr("Not installed")
                                                                            : tr("%1 detected").arg(inputProvider));
                          const bool remoteInstalled = remote.value(QStringLiteral("installed")).toBool();
                          const bool remoteSafe = remote.value(QStringLiteral("softwareEncoding")).toBool();
                          const bool remoteCrash = remote.value(QStringLiteral("gpuCrashDetectedThisBoot")).toBool();
                          QString remoteDetail = tr("Not installed");
                          if (remoteInstalled && remoteCrash && remoteSafe) {
                              remoteDetail = tr("Graphics crash detected earlier · safe software encoding is active");
                          } else if (remoteInstalled && remoteSafe) {
                              remoteDetail = remote.value(QStringLiteral("serviceActive")).toBool()
                                  ? tr("Running with safe software encoding") : tr("Safe software encoding configured · currently stopped");
                          } else if (remoteInstalled) {
                              remoteDetail = tr("Hardware encoding can make the desktop unstable");
                          }
                          add(11, tr("Remote support"), !remoteInstalled || remoteSafe, remoteDetail);
                          status->setText(tr("Check complete"));
                      });
        };
        connect(refresh, &QPushButton::clicked, this, run);
        setCustomContent(page, tr("Diagnostics"), tr("A plain-language check that does not change the computer."));
        run();
    }

    void showMigrationPage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        auto *source = new QLineEdit(page);
        source->setReadOnly(true);
        source->setPlaceholderText(tr("For example, select %1 on a mounted Windows drive").arg(QStringLiteral("C:\\Users\\yourname")));
        auto *choose = new QPushButton(tr("Select Windows user folder"), page);
        auto *row = new QHBoxLayout;
        row->addWidget(source, 1);
        row->addWidget(choose);
        layout->addLayout(row);
        auto *status = new QLabel(tr("Existing files are not overwritten."), page);
        status->setWordWrap(true);
        auto *actions = new QHBoxLayout;
        auto *preview = new QPushButton(tr("Preview first"), page);
        auto *apply = new QPushButton(tr("Transfer files"), page);
        actions->addWidget(preview);
        actions->addWidget(apply);
        actions->addStretch(1);
        layout->addLayout(actions);
        layout->addWidget(status);
        layout->addStretch(1);
        connect(choose, &QPushButton::clicked, this, [this, source] {
            const QString selected = QFileDialog::getExistingDirectory(this, tr("Select the Windows user folder"));
            if (!selected.isEmpty()) {
                source->setText(selected);
            }
        });
        const auto migrate = [this, source, status](bool applyChanges) {
            if (source->text().isEmpty()) {
                status->setText(tr("Select a Windows user folder first."));
                return;
            }
            if (applyChanges
                && QMessageBox::question(this, tr("Transfer files"),
                                         tr("Copy known personal folders? Existing files will be preserved.")) != QMessageBox::Yes) {
                return;
            }
            setTaskFeedback(status);
            startTask(applyChanges ? QStringLiteral("migration-apply") : QStringLiteral("migration-preview"),
                      QStringLiteral("/usr/bin/eczos-migrate"),
                      {applyChanges ? QStringLiteral("--apply") : QStringLiteral("--dry-run"), QStringLiteral("--source"), source->text(), QStringLiteral("--no-gui")},
                      applyChanges ? tr("Transferring files…") : tr("Creating preview…"),
                      [status, applyChanges](int code, const QByteArray &output, const QByteArray &errors) {
                          const QString detail = QString::fromUtf8(code == 0 ? output : errors).trimmed();
                          status->setText(code == 0 ? (applyChanges ? tr("File transfer complete") : tr("Preview complete\n%1").arg(detail))
                                                    : detail.section('\n', -1));
                      });
        };
        connect(preview, &QPushButton::clicked, this, [migrate] { migrate(false); });
        connect(apply, &QPushButton::clicked, this, [migrate] { migrate(true); });
        setCustomContent(page, tr("Transfer files"), tr("Bring documents, photos, music and other personal files over from a Windows profile."));
    }

    void showSupportPage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        auto *privacy = new QLabel(tr("The report contains system information, hardware, storage and failed services. Personal documents, passwords and browser history are not included. The file remains local."), page);
        privacy->setWordWrap(true);
        privacy->setMinimumHeight(100);
        layout->addWidget(privacy);
        auto *button = new QPushButton(tr("Save support report"), page);
        auto *emailButton = new QPushButton(QIcon::fromTheme(QStringLiteral("mail-send")), tr("Email EasyComp Zeeland"), page);
        auto *githubButton = new QPushButton(QIcon::fromTheme(QStringLiteral("tools-report-bug")), tr("Report a problem on GitHub"), page);
        auto *status = new QLabel(page);
        status->setWordWrap(true);
        auto *reportActions = new QHBoxLayout;
        reportActions->addWidget(button);
        reportActions->addWidget(emailButton);
        reportActions->addWidget(githubButton);
        reportActions->addStretch(1);
        layout->addLayout(reportActions);
        layout->addWidget(status);
        auto *activityHeading = new QLabel(tr("Recent ECZOS activity"), page);
        activityHeading->setStyleSheet(QStringLiteral("font-size: 17px; font-weight: 600; margin-top: 8px;"));
        auto *activity = new QPlainTextEdit(page);
        activity->setReadOnly(true); activity->setMaximumHeight(280);
        activity->setPlaceholderText(tr("No recent ECZOS activity was found."));
        auto *refreshActivity = new QPushButton(QIcon::fromTheme(QStringLiteral("view-refresh")), tr("Refresh activity"), page);
        auto *advancedHint = new QLabel(tr("Enable Advanced mode in the sidebar to inspect the privacy-filtered technical activity."), page);
        advancedHint->setWordWrap(true);
        advancedHint->setVisible(!m_advancedMode);
        activityHeading->setVisible(m_advancedMode);
        activity->setVisible(m_advancedMode);
        refreshActivity->setVisible(m_advancedMode);
        layout->addWidget(advancedHint);
        layout->addWidget(activityHeading); layout->addWidget(activity); layout->addWidget(refreshActivity, 0, Qt::AlignLeft);
        layout->addStretch(1);
        const auto createReport = [this, status](const QString &action) {
            setTaskFeedback(status);
            startTask(QStringLiteral("support-") + action, QStringLiteral("/usr/bin/eczos-support-report"), {QStringLiteral("--no-gui")}, tr("Creating support report…"),
                      [status, action](int code, const QByteArray &output, const QByteArray &errors) {
                          const QString detail = QString::fromUtf8(code == 0 ? output : errors).trimmed();
                          if (code != 0) {
                              status->setText(detail.isEmpty() ? tr("Creation failed") : detail.section('\n', -1));
                              return;
                          }
                          QString path;
                          for (const QString &line : detail.split('\n')) {
                              if (line.startsWith(QStringLiteral("ECZOS_REPORT_PATH="))) {
                                  path = line.mid(18).trimmed();
                              }
                          }
                          if (path.isEmpty() || !QFileInfo::exists(path)) {
                              status->setText(tr("The support report could not be found after it was created."));
                              return;
                          }
                          if (action == QStringLiteral("email")) {
                              const QString subject = tr("ECZOS support request");
                              const QString body = tr("Describe what happened, what you expected, and the steps that reproduce the problem. The privacy-filtered ECZOS support report is attached.");
                              const bool opened = QProcess::startDetached(QStringLiteral("/usr/bin/xdg-email"),
                                  {QStringLiteral("--subject"), subject, QStringLiteral("--body"), body,
                                   QStringLiteral("--attach"), path, QStringLiteral("support@easycompzeeland.nl")});
                              status->setText(opened ? tr("A draft email with the report attached was opened. Review it and press Send in your mail app.")
                                                     : tr("The email app could not be opened. The report is saved at %1").arg(path));
                          } else if (action == QStringLiteral("github")) {
                              QFile report(path);
                              if (!report.open(QIODevice::ReadOnly | QIODevice::Text)) {
                                  status->setText(tr("The report could not be read. It is saved at %1").arg(path));
                                  return;
                              }
                              QApplication::clipboard()->setText(QString::fromUtf8(report.readAll()));
                              QUrl url(QStringLiteral("https://github.com/EasyCompZLD/ECZOS/issues/new"));
                              QUrlQuery query;
                              query.addQueryItem(QStringLiteral("title"), QStringLiteral("[ECZOS] "));
                              query.addQueryItem(QStringLiteral("body"), tr("Describe the problem and the steps that reproduce it here. Then paste the privacy-filtered report from your clipboard below."));
                              url.setQuery(query);
                              const bool opened = QDesktopServices::openUrl(url);
                              status->setText(opened ? tr("GitHub was opened and the report was copied. Review the issue, paste the report, and submit it yourself.")
                                                     : tr("GitHub could not be opened. The report is saved at %1").arg(path));
                          } else {
                              status->setText(tr("Support report saved at %1").arg(path));
                          }
                      });
        };
        connect(button, &QPushButton::clicked, this, [createReport] { createReport(QStringLiteral("save")); });
        connect(emailButton, &QPushButton::clicked, this, [createReport] { createReport(QStringLiteral("email")); });
        connect(githubButton, &QPushButton::clicked, this, [createReport] { createReport(QStringLiteral("github")); });
        const auto loadActivity = [this, activity, status] {
            setTaskFeedback(status);
            startTask(QStringLiteral("support-activity"), QStringLiteral("/usr/bin/eczos-logs"),
                      {QStringLiteral("text"), QStringLiteral("--days"), QStringLiteral("7")}, tr("Loading privacy-filtered activity…"),
                      [activity, status](int code, const QByteArray &output, const QByteArray &errors) {
                          activity->setPlainText(QString::fromUtf8(code == 0 ? output : errors).trimmed());
                          status->setText(code == 0 ? tr("Activity updated") : tr("Activity could not be loaded"));
                      });
        };
        connect(refreshActivity, &QPushButton::clicked, this, loadActivity);
        setCustomContent(page, tr("Support"), tr("Create a privacy-conscious technical report for EasyComp Zeeland."));
        if (m_advancedMode) loadActivity();
    }

    void showRecoveryPage()
    {
        auto *page = new QWidget;
        auto *layout = pageLayout(page);
        auto *form = new QFormLayout;
        auto *imagePath = new QLineEdit(m_recoveryImage, page);
        imagePath->setReadOnly(true);
        imagePath->setPlaceholderText(tr("No ISO or IMG selected"));
        auto *chooseImage = new QPushButton(tr("Select local file"), page);
        auto *imageRow = new QHBoxLayout;
        imageRow->addWidget(imagePath, 1);
        imageRow->addWidget(chooseImage);
        form->addRow(tr("1  Installation image"), imageRow);

        auto *releaseBox = new QComboBox(page);
        releaseBox->setPlaceholderText(tr("Online ECZOS versions"));
        auto *catalogButton = new QPushButton(tr("Load online versions"), page);
        auto *downloadButton = new QPushButton(tr("Download"), page);
        downloadButton->setEnabled(false);
        auto *releaseRow = new QHBoxLayout;
        releaseRow->addWidget(releaseBox, 1);
        releaseRow->addWidget(catalogButton);
        releaseRow->addWidget(downloadButton);
        form->addRow(QString(), releaseRow);

        auto *mode = new QComboBox(page);
        mode->addItem(tr("USB drive or SD card"), QStringLiteral("disk"));
        mode->addItem(tr("DVD or Blu-ray"), QStringLiteral("dvd"));
        form->addRow(tr("2  Media type"), mode);

        auto *target = new QComboBox(page);
        target->setPlaceholderText(tr("Select a removable device"));
        auto *refresh = new QPushButton(tr("Refresh"), page);
        auto *targetRow = new QHBoxLayout;
        targetRow->addWidget(target, 1);
        targetRow->addWidget(refresh);
        form->addRow(tr("3  Target device"), targetRow);
        layout->addLayout(form);

        auto *warning = new QLabel(tr("⚠  All data on the selected medium will be erased. The internal system drive is always blocked."), page);
        warning->setWordWrap(true);
        warning->setStyleSheet(QStringLiteral("background: #342a16; color: #ffe4a8; border: 1px solid #6d5420; border-radius: 10px; padding: 16px;"));
        layout->addWidget(warning);
        auto *progress = new QProgressBar(page);
        progress->hide();
        auto *status = new QLabel(tr("Ready to begin"), page);
        status->setWordWrap(true);
        auto *write = new QPushButton(tr("Create media"), page);
        layout->addWidget(progress);
        auto *bottom = new QHBoxLayout;
        bottom->addWidget(status, 1);
        bottom->addWidget(write);
        layout->addLayout(bottom);
        layout->addStretch(1);

        const auto refreshDevices = [mode, target, status] {
            target->clear();
            QProcess lsblk;
            lsblk.start(QStringLiteral("/usr/bin/lsblk"), {QStringLiteral("-Jpo"), QStringLiteral("NAME,TYPE,SIZE,MODEL,TRAN,RM")});
            if (!lsblk.waitForFinished(10000)) {
                status->setText(tr("Devices could not be read."));
                return;
            }
            const QJsonArray devices = QJsonDocument::fromJson(lsblk.readAllStandardOutput()).object().value(QStringLiteral("blockdevices")).toArray();
            const QString wanted = mode->currentData().toString();
            for (const QJsonValue &value : devices) {
                const QJsonObject item = value.toObject();
                const QString type = item.value(QStringLiteral("type")).toString();
                const QString transport = item.value(QStringLiteral("tran")).toString();
                const QString name = item.value(QStringLiteral("name")).toString();
                const bool removable = item.value(QStringLiteral("rm")).toVariant().toBool();
                const bool eligibleDisk = type == QStringLiteral("disk")
                    && (removable || transport == QStringLiteral("usb") || transport == QStringLiteral("mmc") || name.startsWith(QStringLiteral("/dev/mmcblk")));
                if ((wanted == QStringLiteral("dvd") && type != QStringLiteral("rom"))
                    || (wanted == QStringLiteral("disk") && !eligibleDisk)) {
                    continue;
                }
                QString modelName = item.value(QStringLiteral("model")).toString().trimmed();
                if (modelName.isEmpty()) {
                    modelName = type == QStringLiteral("rom") ? tr("Optical drive") : tr("Removable medium");
                }
                target->addItem(QStringLiteral("%1  •  %2  •  %3").arg(modelName, item.value(QStringLiteral("size")).toString(QStringLiteral("?")), name), name);
            }
            status->setText(target->count() ? tr("Devices refreshed") : tr("No suitable removable medium found."));
        };
        connect(refresh, &QPushButton::clicked, this, refreshDevices);
        connect(mode, &QComboBox::currentIndexChanged, this, [refreshDevices] { refreshDevices(); });
        connect(chooseImage, &QPushButton::clicked, this, [this, imagePath] {
            const QString selected = QFileDialog::getOpenFileName(this, tr("Select an ECZOS installation image"), QString(), tr("Installation images (*.iso *.img)"));
            if (!selected.isEmpty()) {
                m_recoveryImage = selected;
                imagePath->setText(selected);
            }
        });
        connect(catalogButton, &QPushButton::clicked, this, [this, releaseBox, downloadButton, status, progress] {
            QFile config(QStringLiteral("/etc/eczos/recovery-media.conf"));
            QString url;
            if (config.open(QIODevice::ReadOnly | QIODevice::Text)) {
                for (const QByteArray &line : config.readAll().split('\n')) {
                    if (line.startsWith("CatalogURL=")) {
                        url = QString::fromUtf8(line.mid(11)).trimmed();
                    }
                }
            }
            if (!url.startsWith(QStringLiteral("https://"))) {
                status->setText(tr("The ECZOS download catalogue is not configured yet. Select a local ISO."));
                return;
            }
            setTaskFeedback(status, progress);
            startTask(QStringLiteral("recovery-catalog"), QStringLiteral("/usr/bin/curl"),
                      {QStringLiteral("--fail"), QStringLiteral("--silent"), QStringLiteral("--show-error"), QStringLiteral("--location"), QStringLiteral("--proto"), QStringLiteral("=https"), QStringLiteral("--tlsv1.2"), url},
                      tr("Loading available ECZOS versions…"),
                      [releaseBox, downloadButton, status](int code, const QByteArray &output, const QByteArray &errors) {
                          releaseBox->clear();
                          const QJsonObject catalog = QJsonDocument::fromJson(output).object();
                          if (code != 0 || catalog.value(QStringLiteral("schema")).toInt() != 1) {
                              status->setText(code == 0 ? tr("The download catalogue has an invalid format.") : QString::fromUtf8(errors).trimmed().section('\n', -1));
                              return;
                          }
                          const QRegularExpression checksum(QStringLiteral("^[0-9a-fA-F]{64}$"));
                          for (const QJsonValue &value : catalog.value(QStringLiteral("releases")).toArray()) {
                              const QJsonObject release = value.toObject();
                              const QString url = release.value(QStringLiteral("url")).toString();
                              const QString sha = release.value(QStringLiteral("sha256")).toString();
                              const QString version = release.value(QStringLiteral("version")).toVariant().toString();
                              if (!version.isEmpty() && url.startsWith(QStringLiteral("https://")) && checksum.match(sha).hasMatch()) {
                                  releaseBox->addItem(QStringLiteral("ECZOS %1  •  %2  •  %3").arg(version, release.value(QStringLiteral("channel")).toString(QStringLiteral("release")), release.value(QStringLiteral("published")).toString(tr("date unknown"))), release);
                              }
                          }
                          downloadButton->setEnabled(releaseBox->count() > 0);
                          status->setText(releaseBox->count() ? tr("Available versions refreshed") : tr("No downloadable versions are available yet."));
                      });
        });
        connect(downloadButton, &QPushButton::clicked, this, [this, releaseBox, imagePath, status, progress] {
            const QJsonObject release = releaseBox->currentData().toJsonObject();
            const QString version = release.value(QStringLiteral("version")).toVariant().toString();
            QString safeVersion = version;
            safeVersion.remove(QRegularExpression(QStringLiteral("[^A-Za-z0-9._-]")));
            if (safeVersion.isEmpty()) {
                return;
            }
            const QString cache = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + QStringLiteral("/recovery-media");
            QDir().mkpath(cache);
            const QString finalPath = cache + QStringLiteral("/ECZOS-") + safeVersion + QStringLiteral(".iso");
            const QString partPath = finalPath + QStringLiteral(".part");
            QFile::remove(partPath);
            setTaskFeedback(status, progress);
            startTask(QStringLiteral("recovery-download"), QStringLiteral("/usr/bin/curl"),
                      {QStringLiteral("--fail"), QStringLiteral("--location"), QStringLiteral("--proto"), QStringLiteral("=https"), QStringLiteral("--tlsv1.2"), QStringLiteral("--output"), partPath, release.value(QStringLiteral("url")).toString()},
                      tr("Downloading ECZOS %1…").arg(version),
                      [this, partPath, finalPath, expected = release.value(QStringLiteral("sha256")).toString().toLower(), imagePath, status, progress](int code, const QByteArray &, const QByteArray &errors) {
                          if (code != 0) {
                              QFile::remove(partPath);
                              status->setText(QString::fromUtf8(errors).trimmed().section('\n', -1));
                              return;
                          }
                          setTaskFeedback(status, progress);
                          startTask(QStringLiteral("recovery-verify"), QStringLiteral("/usr/bin/sha256sum"), {partPath}, tr("Verifying download…"),
                                    [this, partPath, finalPath, expected, imagePath, status](int verifyCode, const QByteArray &output, const QByteArray &) {
                                        const QString actual = QString::fromUtf8(output).section(' ', 0, 0).trimmed().toLower();
                                        if (verifyCode != 0 || actual != expected) {
                                            QFile::remove(partPath);
                                            status->setText(tr("The download verification failed."));
                                            return;
                                        }
                                        QFile::remove(finalPath);
                                        if (!QFile::rename(partPath, finalPath)) {
                                            status->setText(tr("The installation image could not be saved."));
                                            return;
                                        }
                                        m_recoveryImage = finalPath;
                                        imagePath->setText(finalPath);
                                        status->setText(tr("Installation image downloaded and verified"));
                                    });
                      });
        });
        connect(write, &QPushButton::clicked, this, [this, imagePath, mode, target, status, progress] {
            if (imagePath->text().isEmpty() || target->currentData().toString().isEmpty()) {
                status->setText(tr("Select an installation image and target device first."));
                return;
            }
            if (QMessageBox::warning(this, tr("Erase the entire medium?"),
                                     tr("All data on %1 will be erased. This cannot be undone.").arg(target->currentText()),
                                     QMessageBox::Ok | QMessageBox::Cancel, QMessageBox::Cancel) != QMessageBox::Ok) {
                return;
            }
            setTaskFeedback(status, progress);
            startTask(QStringLiteral("recovery-write"), QStringLiteral("/usr/bin/pkexec"),
                      {QStringLiteral("/usr/lib/eczos-recovery-media/write-media"), mode->currentData().toString(), imagePath->text(), target->currentData().toString(), QStringLiteral("--json-progress")},
                      tr("Preparing recovery media…"),
                      [status](int code, const QByteArray &, const QByteArray &errors) {
                          status->setText(code == 0 ? tr("Done. The recovery medium can be removed safely.")
                                                    : QString::fromUtf8(errors).trimmed().section('\n', -1));
                      });
        });
        setCustomContent(page, tr("Create recovery media"), tr("Write an ECZOS installation image to USB, SD card or optical media with visible progress."));
        refreshDevices();
        QTimer::singleShot(0, catalogButton, &QPushButton::click);
    }

    void showCustomPage(const QString &id)
    {
        if (m_task && m_task->state() != QProcess::NotRunning) {
            return;
        }
        if (id == QStringLiteral("eczos:overview")) {
            showOverviewPage();
        } else if (id == QStringLiteral("eczos:time")) {
            openEntry(QStringLiteral("kcm_clock"));
        } else if (id == QStringLiteral("eczos:hardware")) {
            showHardwarePage();
        } else if (id == QStringLiteral("eczos:boot")) {
            showBootPage();
        } else if (id == QStringLiteral("eczos:windows")) {
            showWindowsPage();
        } else if (id == QStringLiteral("eczos:gaming")) {
            showGamingPage();
        } else if (id == QStringLiteral("eczos:remote-input")) {
            showRemoteInputPage();
        } else if (id == QStringLiteral("eczos:network-shares")) {
            showNetworkSharesPage();
        } else if (id == QStringLiteral("eczos:network-optical")) {
            showNetworkOpticalPage();
        } else if (id == QStringLiteral("eczos:recovery")) {
            showRecoveryPage();
        } else if (id == QStringLiteral("eczos:migration")) {
            showMigrationPage();
        } else if (id == QStringLiteral("eczos:diagnostics")) {
            showDiagnosticsPage();
        } else if (id == QStringLiteral("eczos:support")) {
            showSupportPage();
        }
    }

    void showLandingPage()
    {
        auto *landing = new QWidget;
        auto *layout = new QVBoxLayout(landing);
        auto *intro = new QLabel(tr("All %1 installed system modules are available from the sidebar.").arg(m_modules.size()), landing);
        intro->setWordWrap(true);
        intro->setStyleSheet(QStringLiteral("font-size: 18px; font-weight: 600; margin: 12px;"));
        layout->addWidget(intro);
        auto *images = new QHBoxLayout;
        const QList<QPair<QString, QString>> cards = {
            {tr("Appearance"), QStringLiteral("system-appearance.png")},
            {tr("Displays"), QStringLiteral("system-display.png")},
            {tr("Network"), QStringLiteral("system-network.png")},
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
            tr("Save changes?"),
            tr("This module contains changes that have not been saved yet."),
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

    void addTimeHealthPanel(QWidget *wrapper, QVBoxLayout *layout)
    {
        auto *health = new QGroupBox(tr("Automatic date and time"), wrapper);
        auto *healthLayout = new QVBoxLayout(health);
        auto *values = new QLabel(tr("Checking date and time…"), health);
        values->setWordWrap(true);
        auto *notice = new QLabel(health);
        notice->setWordWrap(true);
        notice->setObjectName(QStringLiteral("pageDescription"));
        auto *actions = new QHBoxLayout;
        auto *checkAgain = new QPushButton(QIcon::fromTheme(QStringLiteral("view-refresh")), tr("Check again"), health);
        auto *repair = new QPushButton(QIcon::fromTheme(QStringLiteral("tools-wizard")), tr("Repair automatic time"), health);
        actions->addWidget(checkAgain);
        actions->addWidget(repair);
        actions->addStretch(1);
        auto *status = new QLabel(health);
        status->setWordWrap(true);
        healthLayout->addWidget(values);
        healthLayout->addWidget(notice);
        healthLayout->addLayout(actions);
        healthLayout->addWidget(status);
        layout->insertWidget(0, health);

        auto check = std::make_shared<std::function<void()>>();
        *check = [this, values, notice, repair, status] {
            setTaskFeedback(status);
            startTask(QStringLiteral("time-status"), QStringLiteral("/usr/bin/eczos-time"),
                      {QStringLiteral("status"), QStringLiteral("--json")}, tr("Checking date and time…"),
                      [values, notice, repair, status](int code, const QByteArray &output, const QByteArray &errors) {
                          const QJsonObject data = QJsonDocument::fromJson(output).object();
                          if (code != 0 || data.isEmpty()) {
                              values->setText(tr("Date and time status is unavailable."));
                              notice->setText(QString::fromUtf8(errors).trimmed().section('\n', -1));
                              repair->setEnabled(false);
                              status->clear();
                              return;
                          }
                          const bool synchronized = data.value(QStringLiteral("synchronized")).toBool();
                          const bool providerActive = data.value(QStringLiteral("providerActive")).toBool();
                          values->setText(tr("Timezone: %1\nAutomatic synchronization: %2\nTime service: %3 · %4")
                              .arg(data.value(QStringLiteral("timezone")).toString(),
                                   synchronized ? tr("working") : tr("needs attention"),
                                   data.value(QStringLiteral("provider")).toString(),
                                   providerActive ? tr("running") : tr("stopped")));
                          notice->setText(data.value(QStringLiteral("localRtc")).toBool()
                              ? tr("The hardware clock uses local time for compatibility with another operating system. ECZOS will preserve this setting.")
                              : tr("The hardware clock uses the recommended UTC mode."));
                          repair->setEnabled(!synchronized || !data.value(QStringLiteral("ntpEnabled")).toBool() || !providerActive);
                          status->setText(data.value(QStringLiteral("summary")).toString());
                      });
        };
        connect(checkAgain, &QPushButton::clicked, health, [check] { (*check)(); });
        connect(repair, &QPushButton::clicked, health, [this, status, check] {
            setTaskFeedback(status);
            startTask(QStringLiteral("time-repair"), QStringLiteral("/usr/bin/eczos-time"),
                      {QStringLiteral("repair")}, tr("Repairing automatic time…"),
                      [status, check](int code, const QByteArray &output, const QByteArray &errors) {
                          status->setText(QString::fromUtf8(code == 0 ? output : errors).trimmed().section('\n', -1));
                          if (code == 0) (*check)();
                      });
        });
        (*check)();
    }

    void loadModule(const QString &id)
    {
        if (m_module && m_module->metaData().pluginId() == id) {
            return;
        }
        if (!resolveChanges()) {
            return;
        }
        clearPage();
        const KPluginMetaData data = m_byId.value(id);
        auto *wrapper = new QWidget;
        auto *layout = new QVBoxLayout(wrapper);
        layout->setContentsMargins(0, 0, 0, 0);
        auto *scroll = new QScrollArea(wrapper);
        scroll->setWidgetResizable(true);
        scroll->setFrameShape(QFrame::NoFrame);
        layout->addWidget(scroll, 1);
        m_module = KCModuleLoader::loadModule(data, scroll, {}, m_engine);
        scroll->setWidget(m_module->widget());
        m_module->load();
        if (id == QStringLiteral("kcm_clock")) {
            addTimeHealthPanel(wrapper, layout);
        }
        if (id == QStringLiteral("kcm_nightlight")) {
            auto *appearance = new QGroupBox(tr("ECZOS appearance"), wrapper);
            auto *appearanceLayout = new QVBoxLayout(appearance);
            auto *explanation = new QLabel(
                tr("Choose a light or dark appearance, or let ECZOS follow KDE Night Light."), appearance);
            explanation->setWordWrap(true);
            appearanceLayout->addWidget(explanation);

            auto *choices = new QHBoxLayout;
            auto *choiceGroup = new QButtonGroup(appearance);
            choiceGroup->setExclusive(true);
            const QList<QPair<QString, QString>> modes = {
                {QStringLiteral("nightlight"), tr("Night Light")},
                {QStringLiteral("light"), tr("Light")},
                {QStringLiteral("dark"), tr("Dark")},
            };
            QString selectedMode = QStringLiteral("auto");
            QFile modeFile(QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
                           + QStringLiteral("/eczos/theme-mode"));
            if (modeFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                const QString storedMode = QString::fromUtf8(modeFile.readAll()).trimmed();
                if (storedMode == QStringLiteral("auto")) {
                    selectedMode = QStringLiteral("nightlight");
                } else if (storedMode == QStringLiteral("nightlight") || storedMode == QStringLiteral("light")
                    || storedMode == QStringLiteral("dark")) {
                    selectedMode = storedMode;
                }
            }
            for (int index = 0; index < modes.size(); ++index) {
                auto *button = new QPushButton(modes.at(index).second, appearance);
                button->setCheckable(true);
                button->setIcon(QIcon::fromTheme(index == 0 ? QStringLiteral("weather-clear-night")
                                                            : index == 1 ? QStringLiteral("weather-clear")
                                                                         : QStringLiteral("weather-clear-night")));
                choiceGroup->addButton(button, index);
                choices->addWidget(button, 1);
                if (modes.at(index).first == selectedMode) {
                    button->setChecked(true);
                    choiceGroup->setProperty("appliedId", index);
                }
            }
            appearanceLayout->addLayout(choices);
            auto *status = new QLabel(
                tr("Night Light uses the dark appearance when Night Light is active and the light appearance when it is inactive."), appearance);
            status->setWordWrap(true);
            status->setObjectName(QStringLiteral("pageDescription"));
            appearanceLayout->addWidget(status);
            layout->addWidget(appearance);

            connect(choiceGroup, &QButtonGroup::idClicked, this,
                    [this, choiceGroup, status, modes](int selectedId) {
                        const int previousId = choiceGroup->property("appliedId").toInt();
                        const QString mode = modes.at(selectedId).first;
                        const QString label = modes.at(selectedId).second;
                        setTaskFeedback(status);
                        startTask(QStringLiteral("theme-switch"), QStringLiteral("/usr/bin/eczos-theme-switch"), {mode},
                                  tr("Applying %1 appearance…").arg(label),
                                  [this, choiceGroup, status, previousId, selectedId, label](int code, const QByteArray &, const QByteArray &errors) {
                                      if (code == 0) {
                                          choiceGroup->setProperty("appliedId", selectedId);
                                          status->setText(tr("%1 appearance enabled").arg(label));
                                      } else {
                                          if (QAbstractButton *previous = choiceGroup->button(previousId)) {
                                              previous->setChecked(true);
                                          }
                                          const QString detail = QString::fromUtf8(errors).trimmed();
                                          status->setText(detail.isEmpty() ? tr("Changing the appearance failed.")
                                                                          : detail.section('\n', -1));
                                      }
                                  });
                    });
        }
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
    QProcess *m_task = nullptr;
    QString m_taskKind;
    QByteArray m_taskStdout;
    QByteArray m_taskStderr;
    QByteArray m_eventBuffer;
    QPointer<QLabel> m_taskStatus;
    QPointer<QProgressBar> m_taskProgress;
    std::function<void(int, const QByteArray &, const QByteArray &)> m_taskDone;
    QString m_recoveryImage;
    bool m_advancedMode = false;
};

} // namespace

int main(int argc, char **argv)
{
    QApplication app(argc, argv);
    QTranslator translator;
    const QString locale = QLocale::system().name();
    const QStringList translationRoots = {
        QStringLiteral("/usr/share/eczos/translations"),
        QCoreApplication::applicationDirPath() + QStringLiteral("/../share/eczos/translations"),
    };
    for (const QString &root : translationRoots) {
        if (translator.load(QStringLiteral("eczos-system-settings_%1").arg(locale), root)
            || translator.load(QStringLiteral("eczos-system-settings_%1").arg(locale.left(2)), root)) {
            app.installTranslator(&translator);
            break;
        }
    }
    QApplication::setApplicationName(QObject::tr("ECZOS Settings"));
    QApplication::setOrganizationName(QStringLiteral("EasyComp Zeeland"));

    QCommandLineParser parser;
    parser.setApplicationDescription(QObject::tr("Integrated system settings for ECZOS"));
    parser.addHelpOption();
    QCommandLineOption listOption(QStringLiteral("list-json"), QObject::tr("Show all embedded modules as JSON"));
    QCommandLineOption moduleOption(QStringLiteral("module"), QObject::tr("Open a settings module directly"), QStringLiteral("id"));
    parser.addOption(listOption);
    parser.addOption(moduleOption);
    parser.process(app);

    if (parser.isSet(listOption)) {
        const QList<KPluginMetaData> modules = availableModules();
        QFile output;
        output.open(stdout, QIODevice::WriteOnly);
        output.write(moduleInventory(modules).toJson(QJsonDocument::Compact));
        output.write("\n");
        return 0;
    }

    const QString runtimeDirectory = QStandardPaths::writableLocation(QStandardPaths::RuntimeLocation);
    const QString socketPath = QDir(runtimeDirectory).filePath(QStringLiteral("eczos-system-settings.sock"));
    QLocalSocket existingInstance;
    existingInstance.connectToServer(socketPath);
    if (existingInstance.waitForConnected(250)) {
        existingInstance.write((parser.isSet(moduleOption) ? parser.value(moduleOption).toUtf8() : QByteArray()) + '\n');
        existingInstance.waitForBytesWritten(500);
        return 0;
    }

    QLocalServer::removeServer(socketPath);
    QLocalServer instanceServer;
    if (!instanceServer.listen(socketPath)) {
        QMessageBox::critical(nullptr, QObject::tr("ECZOS Settings"), QObject::tr("The settings window could not be started."));
        return 1;
    }

    const QList<KPluginMetaData> modules = availableModules();
    SettingsWindow window(modules);
    if (parser.isSet(moduleOption) && !window.openEntry(parser.value(moduleOption))) {
        return 2;
    }
    QObject::connect(&instanceServer, &QLocalServer::newConnection, &window, [&instanceServer, &window] {
        while (QLocalSocket *connection = instanceServer.nextPendingConnection()) {
            QObject::connect(connection, &QLocalSocket::disconnected, connection, &QObject::deleteLater);
            QObject::connect(connection, &QLocalSocket::readyRead, &window, [connection, &window] {
                const QString entry = QString::fromUtf8(connection->readAll()).trimmed();
                if (!entry.isEmpty()) {
                    window.openEntry(entry);
                }
                window.showNormal();
                window.raise();
                window.activateWindow();
                connection->disconnectFromServer();
            });
            if (connection->bytesAvailable() > 0) {
                const QString entry = QString::fromUtf8(connection->readAll()).trimmed();
                if (!entry.isEmpty()) {
                    window.openEntry(entry);
                }
                window.showNormal();
                window.raise();
                window.activateWindow();
                connection->disconnectFromServer();
            }
        }
    });
    window.show();
    return app.exec();
}

#include "main.moc"
