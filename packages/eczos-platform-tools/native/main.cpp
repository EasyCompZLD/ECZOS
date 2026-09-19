// SPDX-License-Identifier: GPL-2.0-or-later
// SPDX-FileCopyrightText: 2026 EasyComp Zeeland

#include <QApplication>
#include <QAbstractButton>
#include <QButtonGroup>
#include <QCloseEvent>
#include <QComboBox>
#include <QCommandLineParser>
#include <QDesktopServices>
#include <QDialogButtonBox>
#include <QDir>
#include <QDirIterator>
#include <QFile>
#include <QFileDialog>
#include <QFormLayout>
#include <QGridLayout>
#include <QGroupBox>
#include <QHBoxLayout>
#include <QIcon>
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
#include <QProcess>
#include <QProgressBar>
#include <QPointer>
#include <QPushButton>
#include <QQmlEngine>
#include <QRadioButton>
#include <QRegularExpression>
#include <QLocale>
#include <QTranslator>
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
#include <functional>
#include <initializer_list>
#include <memory>

namespace {

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
        {QStringLiteral("eczos:windows"), QObject::tr("Windows apps"), QObject::tr("Manage Windows programs"), QStringLiteral("application-x-ms-dos-executable")},
        {QStringLiteral("eczos:gaming"), QObject::tr("Gaming"), QObject::tr("Check Steam, Proton and Vulkan"), QStringLiteral("applications-games")},
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
        auto *eczosGroup = new QTreeWidgetItem(m_tree, QStringList(QStringLiteral("ECZOS")));
        eczosGroup->setFlags(Qt::ItemIsEnabled);
        eczosGroup->setExpanded(true);
        for (const EczosPage &page : eczosPages()) {
            auto *item = new QTreeWidgetItem(eczosGroup, QStringList(page.name));
            item->setToolTip(0, page.description);
            item->setData(0, Qt::UserRole, page.id);
            item->setIcon(0, QIcon::fromTheme(page.icon));
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
        auto *toolbar = new QHBoxLayout;
        auto *summary = new QLabel(tr("Each Windows program is managed in its own separate environment."), page);
        summary->setWordWrap(true);
        auto *refresh = new QPushButton(tr("Refresh list"), page);
        toolbar->addWidget(summary, 1);
        toolbar->addWidget(refresh);
        layout->addLayout(toolbar);
        auto *status = new QLabel(page);
        status->setWordWrap(true);
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
            auto *card = new QGroupBox(record.value(QStringLiteral("name")).toString(id), page);
            auto *row = new QHBoxLayout(card);
            const QString appStatus = record.value(QStringLiteral("status")).toString();
            auto *detail = new QLabel(appStatus == QStringLiteral("installed") ? tr("Installed and ready")
                                                                                 : tr("Status: %1").arg(appStatus), card);
            row->addWidget(detail, 1);
            for (const auto &[label, action] : QList<QPair<QString, QString>>{
                     {tr("Start"), QStringLiteral("run")},
                     {tr("Search again"), QStringLiteral("rescan")},
                     {tr("Repair"), QStringLiteral("repair")},
                     {tr("Remove"), QStringLiteral("remove")}}) {
                auto *button = new QPushButton(label, card);
                button->setEnabled(action != QStringLiteral("run") || appStatus == QStringLiteral("installed"));
                connect(button, &QPushButton::clicked, this, [this, id, action, name = card->title(), status] {
                    if (action == QStringLiteral("run")) {
                        QProcess::startDetached(QStringLiteral("/usr/bin/eczos-windows"), {action, id});
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
                              [this](int code, const QByteArray &, const QByteArray &errors) {
                                  if (code == 0) {
                                      showWindowsPage();
                                  } else if (m_taskStatus) {
                                      m_taskStatus->setText(QString::fromUtf8(errors).trimmed().section('\n', -1));
                                  }
                              });
                });
                row->addWidget(button);
            }
            layout->addWidget(card);
        }
        if (count == 0) {
            auto *empty = new QLabel(tr("No Windows apps yet. Open an .exe or .msi file to add an app."), page);
            empty->setAlignment(Qt::AlignCenter);
            empty->setMinimumHeight(130);
            layout->addWidget(empty);
        }
        layout->addWidget(status);
        layout->addStretch(1);
        connect(refresh, &QPushButton::clicked, this, [this] { showWindowsPage(); });
        setCustomContent(page, tr("Windows apps"), tr("Start, repair and remove Windows programs without a separate management app."));
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
                          add(0, tr("Windows apps"), data.value(QStringLiteral("windows")).toBool(), tr("Compatibility layer"));
                          add(1, tr("Gaming"), data.value(QStringLiteral("gaming")).toString() == QStringLiteral("ready"), data.value(QStringLiteral("gaming")).toString());
                          add(2, tr("Apps and Flatpak"), apps.value(QStringLiteral("discover")).toBool() && apps.value(QStringLiteral("flatpak")).toBool(), tr("Software management"));
                          add(3, tr("Backup"), data.value(QStringLiteral("backup")).toBool(), tr("Personal files"));
                          add(4, tr("Phone connection"), data.value(QStringLiteral("phone")).toBool(), QStringLiteral("KDE Connect"));
                          add(5, tr("Printers and scanners"), devices.value(QStringLiteral("printer")).toBool() && devices.value(QStringLiteral("scanner")).toBool(), tr("Device support"));
                          const int failed = data.value(QStringLiteral("failedUnits")).toInt();
                          add(6, tr("System services"), failed == 0, failed == 0 ? tr("No errors found") : tr("%1 service(s) need attention").arg(failed));
                          add(7, QStringLiteral("FreeOffice"), data.value(QStringLiteral("office")).toString() == QStringLiteral("installed"), data.value(QStringLiteral("office")).toString());
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
        auto *button = new QPushButton(tr("Create support report"), page);
        auto *status = new QLabel(page);
        status->setWordWrap(true);
        layout->addWidget(button, 0, Qt::AlignLeft);
        layout->addWidget(status);
        layout->addStretch(1);
        connect(button, &QPushButton::clicked, this, [this, status] {
            setTaskFeedback(status);
            startTask(QStringLiteral("support"), QStringLiteral("/usr/bin/eczos-support-report"), {QStringLiteral("--no-gui")}, tr("Creating support report…"),
                      [status](int code, const QByteArray &output, const QByteArray &errors) {
                          const QString detail = QString::fromUtf8(code == 0 ? output : errors).trimmed();
                          status->setText(detail.isEmpty() ? (code == 0 ? tr("Support report created") : tr("Creation failed")) : detail.section('\n', -1));
                      });
        });
        setCustomContent(page, tr("Support"), tr("Create a privacy-conscious technical report for EasyComp Zeeland."));
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
    }

    void showCustomPage(const QString &id)
    {
        if (m_task && m_task->state() != QProcess::NotRunning) {
            return;
        }
        if (id == QStringLiteral("eczos:overview")) {
            showOverviewPage();
        } else if (id == QStringLiteral("eczos:windows")) {
            showWindowsPage();
        } else if (id == QStringLiteral("eczos:gaming")) {
            showGamingPage();
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
        if (id == QStringLiteral("kcm_nightlight")) {
            auto *appearance = new QGroupBox(tr("ECZOS appearance"), wrapper);
            auto *appearanceLayout = new QVBoxLayout(appearance);
            auto *explanation = new QLabel(
                tr("Choose a light or dark appearance, or let ECZOS follow the time of day."), appearance);
            explanation->setWordWrap(true);
            appearanceLayout->addWidget(explanation);

            auto *choices = new QHBoxLayout;
            auto *choiceGroup = new QButtonGroup(appearance);
            choiceGroup->setExclusive(true);
            const QList<QPair<QString, QString>> modes = {
                {QStringLiteral("auto"), tr("Automatic")},
                {QStringLiteral("light"), tr("Light")},
                {QStringLiteral("dark"), tr("Dark")},
            };
            QString selectedMode = QStringLiteral("auto");
            QFile modeFile(QStandardPaths::writableLocation(QStandardPaths::GenericConfigLocation)
                           + QStringLiteral("/eczos/theme-mode"));
            if (modeFile.open(QIODevice::ReadOnly | QIODevice::Text)) {
                const QString storedMode = QString::fromUtf8(modeFile.readAll()).trimmed();
                if (storedMode == QStringLiteral("auto") || storedMode == QStringLiteral("light")
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
                tr("Automatic uses the light appearance from 08:00 to 19:00 and the dark appearance at night."), appearance);
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
