// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => 'DioHub';

  @override
  String get languageAndRegion => '语言和地区';

  @override
  String get languageSystem => '跟随系统';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSimplifiedChinese => '简体中文';

  @override
  String get commonCancel => '取消';

  @override
  String get commonBack => '返回';

  @override
  String get commonSearch => '搜索';

  @override
  String get commonRetry => '重试';

  @override
  String get commonSignIn => '登录';

  @override
  String get commonShowMore => '显示更多';

  @override
  String get commonNew => '新建';

  @override
  String get commonCode => '代码';

  @override
  String get commonFilter => '筛选';

  @override
  String get commonAuto => '自动';

  @override
  String get commonFree => '免费';

  @override
  String get homeDashboard => '仪表板';

  @override
  String get homeTitle => '主页';

  @override
  String get homeSearchGitHub => '搜索 GitHub';

  @override
  String get homeSearchRepositories => '搜索 GitHub 仓库';

  @override
  String get homeSearchRepositoriesHint => '所有者、仓库或主题……';

  @override
  String get homeBackToSearch => '返回搜索';

  @override
  String get homeNotifications => '通知';

  @override
  String get notificationsInbox => '收件箱';

  @override
  String get notificationsSaved => '已保存';

  @override
  String get notificationsDone => '已完成';

  @override
  String get notificationsAll => '全部';

  @override
  String get notificationsUnread => '未读';

  @override
  String get notificationsSearchHint => '搜索通知';

  @override
  String get notificationsClearSearch => '清除通知搜索';

  @override
  String notificationsSortLabel(String value) {
    return '排序：$value';
  }

  @override
  String notificationsGroupLabel(String value) {
    return '分组：$value';
  }

  @override
  String get notificationsNewestToOldest => '从新到旧';

  @override
  String get notificationsOldestToNewest => '从旧到新';

  @override
  String get notificationsRepository => '仓库';

  @override
  String get notificationsRepositories => '仓库';

  @override
  String get notificationsAllRepositories => '所有仓库';

  @override
  String get notificationsDate => '日期';

  @override
  String get notificationsDateUnknown => '日期未知';

  @override
  String get notificationsRefresh => '刷新通知';

  @override
  String get notificationsMarkAllRead => '全部标为已读';

  @override
  String get notificationsMarkRead => '标为已读';

  @override
  String get notificationsMarkDone => '标为完成';

  @override
  String get notificationsSelectAll => '选择所有已加载通知';

  @override
  String get notificationsClearSelection => '清除选择';

  @override
  String notificationsSelectedCount(int count) {
    return '已选择 $count 项';
  }

  @override
  String notificationsBulkDone(int count) {
    return '已将 $count 条通知标为完成。';
  }

  @override
  String notificationsBulkFailed(int count) {
    return '有 $count 条通知更新失败。';
  }

  @override
  String get notificationsFilters => '筛选';

  @override
  String get notificationsFilterReasons => '通知原因';

  @override
  String get notificationsClearFilters => '清除筛选';

  @override
  String get notificationsAssigned => '分配给我';

  @override
  String get notificationsParticipating => '参与的通知';

  @override
  String get notificationsAuthor => '由我创建';

  @override
  String get notificationsComment => '评论';

  @override
  String get notificationsInvitation => '邀请';

  @override
  String get notificationsFollowing => '正在关注';

  @override
  String get notificationsMentioned => '提及我';

  @override
  String get notificationsReviewRequested => '请求审查';

  @override
  String get notificationsSecurityAlert => '安全警报';

  @override
  String get notificationsStateChange => '状态变化';

  @override
  String get notificationsSubscribed => '已订阅';

  @override
  String get notificationsTeamMention => '提及团队';

  @override
  String get notificationsCiActivity => '持续集成活动';

  @override
  String notificationsReason(String reason) {
    return '原因：$reason';
  }

  @override
  String get notificationsCaughtUp => '通知已全部处理';

  @override
  String get notificationsNoUnread => '没有未读通知。';

  @override
  String get notificationsNoResults => '没有符合当前筛选条件的通知。';

  @override
  String get notificationsLoadError => '无法加载通知。';

  @override
  String get notificationsUpdateError => '无法更新通知。';

  @override
  String get notificationsSignInTitle => '登录后查看通知';

  @override
  String get notificationsSignInBody => 'GitHub 通知仅对你的账号可见。';

  @override
  String get notificationsOpen => '打开通知';

  @override
  String get notificationsAddFilter => '添加新筛选';

  @override
  String get notificationsFilterName => '筛选名称';

  @override
  String get notificationsFilterQuery => '筛选查询';

  @override
  String get notificationsSaveFilter => '保存筛选';

  @override
  String get notificationsCleanupTitle => '清理收件箱。';

  @override
  String get notificationsCleanupBody => '选择当前已加载的已读通知，然后将它们标记为完成。';

  @override
  String get notificationsDismiss => '关闭';

  @override
  String get notificationsGetStarted => '开始';

  @override
  String notificationsSectionUnavailable(String section) {
    return '当前 GitHub API 无法列出“$section”通知。';
  }

  @override
  String get homeCouldNotOpenLink => '无法打开链接。';

  @override
  String homeFeatureNotAvailable(String feature) {
    return '此阶段尚未接入“$feature”。';
  }

  @override
  String get homeNoSystemBrowser => '没有可用的系统浏览器。';

  @override
  String get homeOpenRepositoryOnGitHub => '在 GitHub 上打开仓库';

  @override
  String get homeDirectoryEmpty => '此目录为空。';

  @override
  String get homeParentDirectory => '上级目录';

  @override
  String get homeBackToDirectory => '返回目录';

  @override
  String get homeOpenFileOnGitHub => '在 GitHub 上打开文件';

  @override
  String get homeOpenOnGitHub => '在 GitHub 上打开';

  @override
  String get homeBrowsingGitHubPublicly => '正在公开浏览 GitHub';

  @override
  String get homePublicBrowsing => '公开浏览';

  @override
  String get homeAskAnything => '询问任何内容，或输入 @ 添加上下文';

  @override
  String get homeAddContext => '添加上下文';

  @override
  String get homeSelectModel => '选择模型';

  @override
  String get homeSendPrompt => '发送提示';

  @override
  String get homeAgent => '智能体';

  @override
  String get homeCreateIssue => '创建议题';

  @override
  String get homeWriteCode => '编写代码';

  @override
  String get homePullRequests => '拉取请求';

  @override
  String get homeTopRepositories => '常用仓库';

  @override
  String get homeTopRepositoriesSignInBody => '登录后可查看你最近贡献或创建的仓库。';

  @override
  String get homeFindRepository => '查找仓库……';

  @override
  String get homeFindRepositoryTooltip => '查找仓库';

  @override
  String get homeRepositoriesLoadError => '无法加载仓库。';

  @override
  String get homeNoRepositoriesFound => '未找到仓库。';

  @override
  String get homeRepositorySearch => '仓库搜索';

  @override
  String get homeCloseSearch => '关闭搜索';

  @override
  String get homeSignInToPersonalizeFeed => '登录后获取个性化动态';

  @override
  String get homePublicSearchAvailable => '未登录时仍可搜索公开仓库。';

  @override
  String get homeFeed => '动态';

  @override
  String get homeRefreshActivity => '刷新动态';

  @override
  String get homeActivityNotConnected => '动态流尚未接入。';

  @override
  String get homeFollowingAndWatched => '关注和监视';

  @override
  String get homeSignInToPersonalize => '登录以获得个性化内容';

  @override
  String get homeTopRepositoriesUnavailable => '常用仓库暂不可用。';

  @override
  String get navClose => '关闭导航';

  @override
  String get navAllIssues => '所有议题';

  @override
  String get navAllPullRequests => '所有拉取请求';

  @override
  String get navAllRepositories => '所有仓库';

  @override
  String get globalListsSignInTitle => '登录后查看你的工作';

  @override
  String get globalListsSignInDescription => '登录后即可查看与你的账户相关的议题、拉取请求和仓库。';

  @override
  String get globalListsSignInAction => '登录';

  @override
  String get globalListsAll => '全部';

  @override
  String get globalListsSearchIssues => '搜索你的议题';

  @override
  String get globalListsSearchPullRequests => '搜索你的拉取请求';

  @override
  String get globalListsSearchRepositories => '查找仓库';

  @override
  String globalListsResultsCount(int count) {
    return '$count 个结果';
  }

  @override
  String get globalListsNoIssues => '没有符合筛选条件的议题';

  @override
  String get globalListsNoPullRequests => '没有符合筛选条件的拉取请求';

  @override
  String get globalListsNoRepositories => '没有符合筛选条件的仓库';

  @override
  String get globalListsNoResultsDescription => '请尝试修改搜索文字或筛选条件。';

  @override
  String globalListsRepositoriesFor(String login) {
    return '@$login 可访问的仓库';
  }

  @override
  String globalListsUpdated(String time) {
    return '更新于 $time';
  }

  @override
  String globalListsIssueMetadata(
    String repository,
    int number,
    String action,
    String author,
    String time,
  ) {
    return '$repository #$number，$author 于 $time$action';
  }

  @override
  String get globalListsBestMatch => '最佳匹配';

  @override
  String get globalListsNewest => '最新创建';

  @override
  String get globalListsOldest => '最早创建';

  @override
  String get globalListsMostComments => '评论最多';

  @override
  String get globalListsRecentlyPushed => '最近推送';

  @override
  String get globalListsRecentlyUpdated => '最近更新';

  @override
  String get globalListsName => '名称';

  @override
  String get globalListsMostStars => '星标最多';

  @override
  String get globalListsMostForks => '复刻最多';

  @override
  String get globalListsMirrors => '镜像';

  @override
  String get globalListsForks => '复刻';

  @override
  String get globalListsClearFilters => '清除筛选';

  @override
  String get globalListsRefresh => '刷新结果';

  @override
  String get globalListsLoadError => '无法加载结果。';

  @override
  String get globalListsNewIssue => '新建议题';

  @override
  String get globalListsNewPullRequest => '新建拉取请求';

  @override
  String get globalListsSelectRepository => '选择仓库';

  @override
  String get globalListsChooseIssueTemplate => '选择议题模板';

  @override
  String get globalListsBlankIssue => '空白议题';

  @override
  String get globalListsCreateFlowError => '无法启动新建流程。';

  @override
  String get navProjects => '项目';

  @override
  String get navDiscussions => '讨论';

  @override
  String get navCodespaces => 'Codespaces';

  @override
  String get navCopilot => 'Copilot';

  @override
  String get navExplore => '探索';

  @override
  String get navMarketplace => '市场';

  @override
  String get navMcpRegistry => 'MCP 注册表';

  @override
  String get accountSwitch => '切换账号';

  @override
  String get accountSetStatus => '设置状态';

  @override
  String get accountProfile => '个人资料';

  @override
  String get accountRepositories => '仓库';

  @override
  String get accountStars => '星标';

  @override
  String get accountGists => 'Gist';

  @override
  String get accountOrganizations => '组织';

  @override
  String get accountEnterprises => '企业';

  @override
  String get accountSponsors => '赞助';

  @override
  String get accountSettings => '设置';

  @override
  String get accountCopilotSettings => 'Copilot 设置';

  @override
  String get accountFeaturePreview => '功能预览';

  @override
  String get accountAppearance => '外观';

  @override
  String get accountAccessibility => '无障碍';

  @override
  String get accountTryEnterprise => '试用企业版';

  @override
  String get accountSignOut => '退出登录';

  @override
  String get accountSignOutAllTitle => '退出所有账号？';

  @override
  String get accountSignOutAllBody => '这会从此设备移除所有已保存的 DioHub 账号及其本地访问令牌。';

  @override
  String get profileOverview => '概览';

  @override
  String get profileRepositories => '仓库';

  @override
  String get profileProjects => '项目';

  @override
  String get profilePackages => '软件包';

  @override
  String get profileStars => '星标';

  @override
  String get profileRefresh => '刷新个人资料';

  @override
  String get profileOptions => '个人资料选项';

  @override
  String get profileOpenLegacyLayout => '打开旧版个人资料';

  @override
  String get profileEdit => '编辑个人资料';

  @override
  String get profileFollow => '关注';

  @override
  String get profileUnfollow => '取消关注';

  @override
  String profileFollowersCount(int count) {
    return '$count 位关注者';
  }

  @override
  String profileFollowingCount(int count) {
    return '正在关注 $count 人';
  }

  @override
  String get profilePinned => '置顶';

  @override
  String get profileContributions => '贡献';

  @override
  String get profileContributionActivity => '贡献活动';

  @override
  String get profileContributionsLoadError => '无法加载贡献记录。';

  @override
  String profileLoadError(String login) {
    return '无法加载 $login 的个人资料。';
  }

  @override
  String get changelogLatest => '最新产品动态';

  @override
  String get changelogEmpty => '暂无产品动态。';

  @override
  String get changelogViewAll => '查看全部动态 →';

  @override
  String get changelogLoadError => '无法加载 GitHub 产品动态。';

  @override
  String get relativeJustNow => '刚刚';

  @override
  String relativeMinutesAgo(int count) {
    return '$count 分钟前';
  }

  @override
  String relativeHoursAgo(int count) {
    return '$count 小时前';
  }

  @override
  String get relativeYesterday => '昨天';

  @override
  String relativeDaysAgo(int count) {
    return '$count 天前';
  }

  @override
  String relativeWeeksAgo(int count) {
    return '$count 周前';
  }

  @override
  String relativeMonthsAgo(int count) {
    return '$count 个月前';
  }

  @override
  String relativeYearsAgo(int count) {
    return '$count 年前';
  }

  @override
  String get repoDashboard => '仪表板';

  @override
  String get repoRepository => '仓库';

  @override
  String get repoLegacyView => '旧版视图';

  @override
  String get repoOpenNavigation => '打开导航';

  @override
  String get repoSearchGitHub => '搜索 GitHub';

  @override
  String get repoRefreshRepository => '刷新仓库';

  @override
  String get repoOptions => '仓库选项';

  @override
  String get repoOpenLegacyLayout => '打开旧版布局';

  @override
  String get repoOpenNewLayout => '打开新版布局';

  @override
  String get repoLoading => '正在加载仓库……';

  @override
  String get repoUnavailable => '仓库不可用';

  @override
  String repoLoadError(String error) {
    return '加载仓库时出错：$error';
  }

  @override
  String get repoCode => '代码';

  @override
  String get repoIssues => '议题';

  @override
  String get repoPullRequests => '拉取请求';

  @override
  String get repoActions => '操作';

  @override
  String get repoProjects => '项目';

  @override
  String get repoWiki => 'Wiki';

  @override
  String get repoSecurity => '安全';

  @override
  String get repoInsights => '洞察';

  @override
  String get repoPublic => '公开';

  @override
  String get repoPrivate => '私有';

  @override
  String get repoArchived => '已归档';

  @override
  String repoForkedFrom(String repository) {
    return '复刻自 $repository';
  }

  @override
  String get repoAbout => '关于';

  @override
  String get repoNoDescription => '未提供描述。';

  @override
  String get repoContributing => '贡献指南';

  @override
  String get repoSecurityPolicy => '安全策略';

  @override
  String get wikiPages => 'Wiki 页面';

  @override
  String wikiCurrentPage(String page) {
    return '当前页面：$page';
  }

  @override
  String get wikiNoPages => '暂无 Wiki 页面';

  @override
  String get wikiNoPagesDescription => '此仓库尚未创建 Wiki。';

  @override
  String get wikiCreateOnGitHub => '在 GitHub 上创建 Wiki';

  @override
  String get wikiOpenOnGitHub => '在 GitHub 上打开 Wiki';

  @override
  String get wikiLoadError => '无法加载此仓库的 Wiki。';

  @override
  String get wikiPageLoadError => '无法打开 Wiki 页面。';

  @override
  String get issueDetailLoadError => '无法加载此议题。';

  @override
  String get pullRequestDetailLoadError => '无法加载此拉取请求。';

  @override
  String repoStarsCount(String count) {
    return '$count 个星标';
  }

  @override
  String repoForksCount(String count) {
    return '$count 个复刻';
  }

  @override
  String repoWatchingCount(String count) {
    return '$count 人监视';
  }

  @override
  String repoBranchesCount(String count) {
    return '$count 个分支';
  }

  @override
  String repoTagsCount(String count) {
    return '$count 个标签';
  }

  @override
  String get repoReleases => '发行版';

  @override
  String get repoLatest => '最新';

  @override
  String get repoSponsorProject => '赞助此项目';

  @override
  String get repoLanguages => '语言';

  @override
  String get repoContributors => '贡献者';

  @override
  String get repoLicense => '许可证';

  @override
  String get repoDocumentNotFound => '所选分支中没有此文档。';

  @override
  String repoDocumentLoadError(String error) {
    return '无法加载此文档：$error';
  }

  @override
  String get repoFunding => '赞助';

  @override
  String repoWatchCount(String count) {
    return '监视 $count';
  }

  @override
  String repoForkCount(String count) {
    return '复刻 $count';
  }

  @override
  String repoStarCount(String count) {
    return '星标 $count';
  }

  @override
  String get repoAllActivity => '所有活动';

  @override
  String get repoNotWatching => '不监视';

  @override
  String get repoIgnore => '忽略';

  @override
  String repoNotMigrated(String tab) {
    return '$tab 尚未迁移';
  }

  @override
  String get repoPhaseCodeOnly => '当前阶段只重写仓库的代码页面。现有功能请使用旧版布局。';

  @override
  String get repoReadme => 'README';

  @override
  String get repoEditReadme => '在 GitHub 上编辑 README';

  @override
  String get repoEditReadmeRequiresWrite => '编辑 README 需要写入权限';

  @override
  String get repoReadmeOutlineUnavailable => '当前阶段尚未接入 README 大纲。';

  @override
  String get repoOpenSubmoduleUnavailable => '当前阶段尚不支持打开子模块。';

  @override
  String get repoFileSearchUnavailable => '当前阶段尚未接入全仓库文件搜索。';

  @override
  String get repoGoToFile => '转到文件';

  @override
  String get repoClearFileFilter => '清除文件筛选';

  @override
  String get repoFilterCurrentDirectory => '筛选当前目录';

  @override
  String get repoGoToFileUnavailable => '转到文件（尚未接入）';

  @override
  String get repoCreateNewFile => '新建文件';

  @override
  String get repoCodeOptions => '代码选项';

  @override
  String repoBrowsingCommit(String commit) {
    return '正在浏览提交 $commit，编辑已禁用。';
  }

  @override
  String get repoDefaultBranch => '默认分支';

  @override
  String get repoSwitchBranch => '切换分支……';

  @override
  String get repoSwitchTag => '切换标签……';

  @override
  String get repoUploadFilesUnavailable => '上传文件（尚未接入）';

  @override
  String get repoAddFile => '添加文件';

  @override
  String get repoViewUpstream => '查看上游';

  @override
  String get repoLoadingLatestCommit => '正在加载最新提交……';

  @override
  String get repoLatestCommitUnavailable => '无法获取最新提交';

  @override
  String get repoRetryLatestCommit => '重试加载最新提交';

  @override
  String get repoNoCommitInformation => '当前目录没有提交信息';

  @override
  String get repoUnknownAuthor => '未知作者';

  @override
  String get repoNameColumn => '名称';

  @override
  String get repoLastCommitColumn => '最近提交';

  @override
  String get repoUpdatedColumn => '更新时间';

  @override
  String get repoCouldNotLoadFiles => '无法加载仓库文件';

  @override
  String get repoNoMatchingFiles => '没有匹配的文件';

  @override
  String get repoDirectoryEmpty => '当前目录为空';

  @override
  String get repoClearFilterHint => '清除文件筛选后可显示全部项。';

  @override
  String get repoCloneRepository => '克隆仓库';

  @override
  String get repoDirectory => '目录';

  @override
  String get repoSubmodule => '子模块';

  @override
  String repoReadmeLoadError(String error) {
    return '无法加载 README：$error';
  }

  @override
  String get repoNoReadme => '没有 README';

  @override
  String get repoNoReadmeBody => '该仓库没有 README 文件。';

  @override
  String get repoSearchBranches => '搜索分支……';

  @override
  String get repoSearchTags => '搜索标签……';

  @override
  String get repoDefault => '默认';

  @override
  String get repoCurrent => '当前';

  @override
  String get repoCopyCloneUrl => '复制克隆地址';

  @override
  String get repoOtherLanguages => '其他';

  @override
  String get repoAllIssues => '所有议题';

  @override
  String get repoNewIssue => '新建议题';

  @override
  String get repoNewPullRequest => '新建拉取请求';

  @override
  String get repoFilters => '筛选';

  @override
  String get repoSearchIssues => '搜索议题';

  @override
  String get repoSearchPullRequests => '搜索拉取请求';

  @override
  String get repoOpen => '开启';

  @override
  String get repoClosed => '已关闭';

  @override
  String get repoSort => '排序';

  @override
  String get repoAssignedToMe => '分配给我';

  @override
  String get repoCreatedByMe => '由我创建';

  @override
  String get repoMentioned => '提及我';

  @override
  String get repoRecentActivity => '最近活动';

  @override
  String get repoViews => '视图';

  @override
  String get repoMilestones => '里程碑';

  @override
  String get repoLabels => '标签';

  @override
  String get repoAuthor => '作者';

  @override
  String get repoReviews => '审查';

  @override
  String get repoAssignee => '受理人';

  @override
  String get filterClearAll => '清除全部';

  @override
  String get filterDone => '完成';

  @override
  String get filterMoreFilters => '更多筛选';

  @override
  String get filterAdvanced => '高级筛选';

  @override
  String get filterAdvancedQueryHint => '例如：is:open label:bug';

  @override
  String filterSelect(String section) {
    return '选择$section';
  }

  @override
  String filterSearch(String section) {
    return '搜索$section……';
  }

  @override
  String filterEnter(String section) {
    return '输入$section……';
  }

  @override
  String get filterSearchLabels => '搜索标签……';

  @override
  String get filterSearchAssignees => '搜索受理人……';

  @override
  String get filterApply => '应用';

  @override
  String get filterAfter => '晚于……';

  @override
  String get filterBefore => '早于……';

  @override
  String get filterRange => '范围……';

  @override
  String get filterMinimum => '最小值';

  @override
  String get filterMaximum => '最大值';

  @override
  String get filterNoOptions => '无可用选项';

  @override
  String get filterOptionsLoadError => '无法加载选项';

  @override
  String get filterNoMilestone => '无里程碑';

  @override
  String get filterUnsupportedPicker => '暂不支持此筛选器。';

  @override
  String get filterNoItemsFound => '未找到项目';

  @override
  String get filterStatus => '状态';

  @override
  String get filterLabel => '标签';

  @override
  String get filterMilestone => '里程碑';

  @override
  String get filterBaseBranch => '基准分支';

  @override
  String get filterHeadBranch => '源分支';

  @override
  String get filterCreated => '创建时间';

  @override
  String get filterUpdated => '更新时间';

  @override
  String get filterComments => '评论';

  @override
  String get filterReactions => '反应';

  @override
  String get filterInteractions => '互动';

  @override
  String get filterDraft => '草稿';

  @override
  String get filterReviewStatus => '审查状态';

  @override
  String get filterReviewedBy => '审查人';

  @override
  String get filterReviewRequested => '已请求审查';

  @override
  String get filterTeamRequested => '已请求团队审查';

  @override
  String get filterLinkedIssue => '关联议题';

  @override
  String get filterExclude => '排除';

  @override
  String get filterClosed => '关闭时间';

  @override
  String get filterMerged => '合并时间';

  @override
  String get filterOptionMerged => '已合并';

  @override
  String get filterOptionBestMatch => '最佳匹配';

  @override
  String get filterOptionNewest => '最新创建';

  @override
  String get filterOptionOldest => '最早创建';

  @override
  String get filterOptionMostComments => '评论最多';

  @override
  String get filterOptionRecentlyUpdated => '最近更新';

  @override
  String get filterOptionNoReview => '无审查';

  @override
  String get filterOptionReviewRequired => '需要审查';

  @override
  String get filterOptionApproved => '已批准';

  @override
  String get filterOptionChangesRequested => '已请求更改';

  @override
  String get filterOptionDraftOnly => '仅草稿';

  @override
  String get filterOptionNonDraftOnly => '仅非草稿';

  @override
  String get filterOptionHasLinkedPullRequest => '有关联的拉取请求';

  @override
  String get filterOptionHasLinkedIssue => '有关联的议题';

  @override
  String get filterOptionNoLabels => '无标签';

  @override
  String get filterOptionNoMilestone => '无里程碑';

  @override
  String get filterOptionNoAssignee => '无受理人';

  @override
  String get repoIssuesUnavailable => '议题不可用';

  @override
  String get repoIssuesDisabled => '此仓库已禁用议题。';

  @override
  String get repoNoOpenIssues => '暂无开启的议题。';

  @override
  String get repoNoClosedIssues => '暂无已关闭的议题。';

  @override
  String get repoNoOpenPullRequests => '暂无开启的拉取请求。';

  @override
  String get repoNoClosedPullRequests => '暂无已关闭的拉取请求。';

  @override
  String get repoAdjustSearchFilters => '请尝试调整搜索筛选条件。';

  @override
  String get repoIssuePullLoadError => '无法加载此列表。';

  @override
  String get publicGitHubRateLimitReached =>
      '已达到 GitHub 未登录 API 的请求限额。请登录以提高限额，或稍后重试。';

  @override
  String get repoSignInRequired => '登录后继续';

  @override
  String get repoAccountStateLoadError => '无法读取本机账户状态。';

  @override
  String get repoSignInToBrowseIssues => '登录后可浏览和筛选此仓库的议题。';

  @override
  String get repoSignInToBrowsePullRequests => '登录后可浏览和筛选此仓库的拉取请求。';

  @override
  String get repoListOpened => '已开启';

  @override
  String get repoListClosed => '已关闭';

  @override
  String get repoListDraft => '标记为草稿';

  @override
  String get repoListMerged => '已合并';

  @override
  String repoIssuePullListMetadata(
    int number,
    String author,
    String action,
    String time,
  ) {
    return '#$number · $author 于$time$action';
  }

  @override
  String repoCommentsCount(int count) {
    return '$count 条评论';
  }

  @override
  String get repoSecondaryTabSignInBody => '仓库操作、项目、安全和洞察使用需要登录的 GitHub 接口。';

  @override
  String get repoAllWorkflows => '所有工作流';

  @override
  String get repoWorkflow => '工作流';

  @override
  String get repoWorkflowRun => '工作流运行';

  @override
  String repoWorkflowRunsCount(int count) {
    return '$count 次工作流运行';
  }

  @override
  String get repoFilterBranch => '按分支筛选';

  @override
  String get repoNoWorkflowRuns => '没有工作流运行';

  @override
  String get repoNoWorkflowRunsBody => '当前工作流没有符合分支筛选条件的运行记录。';

  @override
  String get repoActionsLoadError => '无法加载工作流运行';

  @override
  String get repoWorkflowsLoadError => '无法加载工作流';

  @override
  String get repoProjectsDescription => '仓库项目用于跨议题和拉取请求跟踪工作。';

  @override
  String get repoProjectsLoadError => '无法加载项目';

  @override
  String get repoNoProjects => '没有项目';

  @override
  String get repoNoProjectsBody => '此仓库在当前排序条件下没有项目。';

  @override
  String get repoSortTitle => '标题';

  @override
  String repoProjectItemsCount(int count) {
    return '$count 个条目';
  }

  @override
  String repoUpdatedTime(String time) {
    return '更新于 $time';
  }

  @override
  String get repoSecurityOverview => '安全概览';

  @override
  String get repoSecurityPolicyChecking => '正在检查默认分支中的安全策略。';

  @override
  String get repoSecurityPolicyMissing => '默认分支中未找到 SECURITY.md 安全策略。';

  @override
  String get repoSecurityPolicyUnavailable => '无法检查安全策略。';

  @override
  String repoSecurityPolicyFound(String path) {
    return '已检测到安全策略：$path';
  }

  @override
  String get repoDependabot => 'Dependabot';

  @override
  String get repoCodeScanning => '代码扫描';

  @override
  String get repoSecretScanning => '机密扫描';

  @override
  String get repoNoDependabotAlerts => '没有 Dependabot 警报';

  @override
  String get repoNoCodeScanningAlerts => '没有代码扫描警报';

  @override
  String get repoNoSecretScanningAlerts => '没有机密扫描警报';

  @override
  String get repoSecurityNoAlertsBody => '此仓库和当前账户目前没有可见警报。';

  @override
  String get repoSecurityDataUnavailable => '安全数据不可用';

  @override
  String repoSecurityPermissionBody(String error) {
    return 'GitHub 可能要求仓库管理权限，或者此功能尚未启用。$error';
  }

  @override
  String repoSecurityAlertsLoaded(int count) {
    return '已加载 $count 条可见警报';
  }

  @override
  String get repoUnknownLocation => '未知位置';

  @override
  String get repoSecret => '机密';

  @override
  String get repoPulse => '脉搏';

  @override
  String get repoTraffic => '流量';

  @override
  String get repoCommunityStandards => '社区标准';

  @override
  String get repoCommitActivity => '提交活动';

  @override
  String repoCommitsLastYear(int count) {
    return '过去一年有 $count 次提交';
  }

  @override
  String get repoNoContributors => '没有可用的贡献者统计。';

  @override
  String get repoUnknownContributor => '未知贡献者';

  @override
  String repoContributionsCount(int count) {
    return '$count 次贡献';
  }

  @override
  String get repoClones => '克隆';

  @override
  String get repoTopReferrers => '主要引荐来源';

  @override
  String get repoPopularContent => '热门内容';

  @override
  String get repoTotal => '总计';

  @override
  String get repoUnique => '独立用户';

  @override
  String repoUniqueVisitors(int count) {
    return '$count 位独立访客';
  }

  @override
  String get repoNoInsightData => '此区块暂无可用数据。';

  @override
  String get repoInsightsDataUnavailable => '洞察数据不可用';

  @override
  String repoInsightsPermissionBody(String error) {
    return '部分仓库统计存在延迟或需要推送权限。$error';
  }

  @override
  String repoCommunityHealth(int percent) {
    return '社区资料完整度：$percent%';
  }

  @override
  String get repoCodeOfConduct => '行为准则';

  @override
  String get repoIssueTemplate => '议题模板';

  @override
  String get repoPullRequestTemplate => '拉取请求模板';

  @override
  String get activityNoRecent => '暂无近期动态';

  @override
  String get activityNoRecentBody => '你关注的用户和仓库动态将显示在这里。';

  @override
  String get activityRefresh => '刷新';

  @override
  String activityLoadMoreError(String error) {
    return '无法加载更多动态：$error';
  }

  @override
  String activityIssueState(String action, int count) {
    String _temp0 = intl.Intl.selectLogic(action, {
      'opened': '创建了 $count 个议题',
      'closed': '关闭了 $count 个议题',
      'reopened': '重新打开了 $count 个议题',
      'readyForReview': '将 $count 个议题标记为就绪',
      'convertedToDraft': '将 $count 个议题转为草稿',
      'other': '更新了 $count 个议题',
    });
    return '$_temp0';
  }

  @override
  String activityPullRequestState(String action, int count) {
    String _temp0 = intl.Intl.selectLogic(action, {
      'opened': '创建了 $count 个拉取请求',
      'closed': '关闭了 $count 个拉取请求',
      'reopened': '重新打开了 $count 个拉取请求',
      'merged': '合并了 $count 个拉取请求',
      'readyForReview': '将 $count 个拉取请求标记为可审查',
      'convertedToDraft': '将 $count 个拉取请求转为草稿',
      'other': '更新了 $count 个拉取请求',
    });
    return '$_temp0';
  }

  @override
  String activityPush(int commits, int branches) {
    String _temp0 = intl.Intl.pluralLogic(
      branches,
      locale: localeName,
      other: '向 $branches 个分支推送了 $commits 个提交',
      one: '推送了 $commits 个提交',
    );
    return '$_temp0';
  }

  @override
  String get activityLabelsUpdated => '更新了标签';

  @override
  String activityLabelsAdded(int count) {
    return '添加了 $count 个标签';
  }

  @override
  String activityLabelsRemoved(int count) {
    return '移除了 $count 个标签';
  }

  @override
  String activityComments(String action, int count) {
    String _temp0 = intl.Intl.selectLogic(action, {
      'created': '添加了 $count 条评论',
      'edited': '编辑了 $count 条评论',
      'deleted': '删除了 $count 条评论',
      'other': '更新了 $count 条评论',
    });
    return '$_temp0';
  }

  @override
  String activityReferences(String action, String kind, int count) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'branch': '创建了 $count 个分支',
      'tag': '创建了 $count 个标签',
      'other': '创建了 $count 个引用',
    });
    String _temp1 = intl.Intl.selectLogic(kind, {
      'branch': '删除了 $count 个分支',
      'tag': '删除了 $count 个标签',
      'other': '删除了 $count 个引用',
    });
    String _temp2 = intl.Intl.selectLogic(action, {
      'created': '$_temp0',
      'deleted': '$_temp1',
      'other': '更新了 $count 个引用',
    });
    return '$_temp2';
  }

  @override
  String activityStarredRepositories(int count) {
    return '为 $count 个仓库添加了星标';
  }

  @override
  String activityForkedRepositories(int count) {
    return '复刻了 $count 个仓库';
  }

  @override
  String activityMadeRepositoriesPublic(int count) {
    return '将 $count 个仓库设为公开';
  }

  @override
  String activityMembers(String action, int count) {
    String _temp0 = intl.Intl.selectLogic(action, {
      'removed': '移除了 $count 名成员',
      'other': '添加了 $count 名成员',
    });
    return '$_temp0';
  }

  @override
  String activityAssignedIssues(String action, int count) {
    String _temp0 = intl.Intl.selectLogic(action, {
      'unassigned': '取消指派了 $count 个议题',
      'other': '指派了 $count 个议题',
    });
    return '$_temp0';
  }

  @override
  String activityReviews(String state, int count) {
    String _temp0 = intl.Intl.selectLogic(state, {
      'approved': '批准了 $count 个拉取请求',
      'changesRequested': '在 $count 个拉取请求上请求更改',
      'dismissed': '驳回了 $count 个拉取请求上的审查',
      'other': '审查了 $count 个拉取请求',
    });
    return '$_temp0';
  }

  @override
  String activityPublishedReleases(int count) {
    return '发布了 $count 个发行版';
  }

  @override
  String activityStartedDiscussions(int count) {
    return '发起了 $count 个讨论';
  }

  @override
  String activityUpdatedWikiPages(int count) {
    return '更新了 $count 个 Wiki 页面';
  }

  @override
  String activityPerformedActions(int count) {
    return '执行了 $count 个操作';
  }

  @override
  String activityJoinTwo(String first, String second) {
    return '$first、$second';
  }

  @override
  String activityJoinMany(String head, String last) {
    return '$head、$last';
  }

  @override
  String get settingsTitle => '设置';

  @override
  String get settingsPageDescription => '在一处管理 GitHub 账户与 DioHub 应用偏好。';

  @override
  String get settingsPreferences => '偏好设置';

  @override
  String get settingsCategory => '设置分类';

  @override
  String get settingsGeneral => '常规';

  @override
  String get settingsAppearance => '外观';

  @override
  String get settingsAccessibility => '无障碍';

  @override
  String get settingsCodeAndRepositories => '代码与仓库';

  @override
  String get settingsNotifications => '通知';

  @override
  String get settingsPrivacy => '隐私与诊断';

  @override
  String get settingsAbout => '关于';

  @override
  String get settingsSaveError => '无法保存此设置。';

  @override
  String get settingsGeneralDescription => '选择应用语言、信息密度和默认浏览行为。';

  @override
  String get settingsAppLanguage => '应用语言';

  @override
  String get settingsAppLanguageDescription => '跟随操作系统，或为 DioHub 单独选择语言。';

  @override
  String get settingsLayout => '布局';

  @override
  String get settingsLayoutDescription => '在 Android 与桌面端共享布局中使用同一套密度。';

  @override
  String get settingsDensity => '信息密度';

  @override
  String get settingsDensityDescription => '调整间距，但不缩小文字或触控目标。';

  @override
  String get settingsDensityCompact => '紧凑';

  @override
  String get settingsDensityDefault => '默认';

  @override
  String get settingsDensitySpacious => '宽松';

  @override
  String get settingsStickyHeaders => '固定区块标题';

  @override
  String get settingsStickyHeadersDescription => '滚动支持此功能的旧页面时保留区块上下文。';

  @override
  String get settingsFeedAndSearch => '动态与搜索';

  @override
  String get settingsGroupRelatedActivity => '合并相关动态';

  @override
  String get settingsGroupRelatedActivityDescription =>
      '将相关的 GitHub 事件合并为一条动态。';

  @override
  String get settingsTimelineFeed => '时间线动态';

  @override
  String get settingsTimelineFeedDescription => '使用连续时间线显示动态，而不是普通卡片。';

  @override
  String get settingsFuzzySearch => '模糊本地筛选';

  @override
  String get settingsFuzzySearchDescription => '在客户端筛选中匹配近似文本。';

  @override
  String get settingsAppearanceDescription => '选择颜色模式，以及个人资料颜色对界面的影响方式。';

  @override
  String get settingsTheme => '主题';

  @override
  String get settingsThemeDescription => 'Material 3 颜色保持集中管理并即时响应。';

  @override
  String get settingsThemeMode => '主题模式';

  @override
  String get settingsThemeModeDescription => '跟随系统，或让 DioHub 始终使用浅色或深色。';

  @override
  String get settingsThemeSystem => '跟随系统';

  @override
  String get settingsThemeLight => '浅色';

  @override
  String get settingsThemeDark => '深色';

  @override
  String get settingsMaterialYou => '使用系统颜色';

  @override
  String get settingsMaterialYouDescription => '平台支持时使用动态 Material You 颜色。';

  @override
  String get settingsProfileColors => '个人资料颜色';

  @override
  String get settingsProfileColorsDescription => '可将头像颜色混合到个人资料页面。';

  @override
  String get settingsProfileTheme => '基于个人资料的颜色';

  @override
  String get settingsProfileThemeDescription => '查看个人资料时应用局部配色。';

  @override
  String get settingsProfileThemeIntensity => '颜色强度';

  @override
  String get settingsProfileThemeIntensityDescription => '控制个人资料颜色的混合强度。';

  @override
  String get settingsAccessibilityDescription => '在保留平台无障碍偏好的同时控制动效与触感反馈。';

  @override
  String get settingsMotion => '动效';

  @override
  String get settingsMotionDescription => '操作系统的“减少动态效果”偏好始终优先。';

  @override
  String get settingsAnimationLevel => '动画级别';

  @override
  String get settingsAnimationLevelDescription => '选择 DioHub 添加多少界面动效。';

  @override
  String get settingsAnimationNone => '无';

  @override
  String get settingsAnimationReduced => '减少';

  @override
  String get settingsAnimationNormal => '正常';

  @override
  String get settingsAnimationEnhanced => '增强';

  @override
  String get settingsFeedback => '反馈';

  @override
  String get settingsHaptics => '触感反馈';

  @override
  String get settingsHapticsDescription => '控制受支持设备上的振动反馈。';

  @override
  String get settingsHapticsOn => '开启';

  @override
  String get settingsHapticsReduced => '减少';

  @override
  String get settingsHapticsOff => '关闭';

  @override
  String get settingsCodeAndRepositoriesDescription => '设置仓库入口行为、文件浏览详情与差异可读性。';

  @override
  String get settingsRepositoryDefaults => '仓库默认项';

  @override
  String get settingsDefaultRepositoryTab => '默认仓库标签页';

  @override
  String get settingsDefaultRepositoryTabDescription => '仓库链接未指定目标时打开此标签页。';

  @override
  String get settingsCommits => '提交';

  @override
  String get settingsCodeBrowser => '代码浏览器';

  @override
  String get settingsFileSort => '文件排序';

  @override
  String get settingsFileSortDescription => '选择目录与文件的排列方式。';

  @override
  String get settingsSortType => '类型';

  @override
  String get settingsSortNameAscending => '名称 A–Z';

  @override
  String get settingsSortNameDescending => '名称 Z–A';

  @override
  String get settingsSortSize => '大小';

  @override
  String get settingsSortExtension => '扩展名';

  @override
  String get settingsShowDotfiles => '显示点文件';

  @override
  String get settingsShowDotfilesDescription => '包含名称以点号开头的文件和目录。';

  @override
  String get settingsShowFileMetadata => '显示文件元数据';

  @override
  String get settingsShowFileMetadataDescription => '在文件列表中显示可用的大小与类型信息。';

  @override
  String get settingsShowGeneratedFiles => '显示生成文件';

  @override
  String get settingsShowGeneratedFilesDescription => '包含 GitHub 识别为自动生成的文件。';

  @override
  String get settingsShowLastCommit => '显示每个路径的最近提交';

  @override
  String get settingsShowLastCommitDescription => '获取可见路径的提交信息。大型目录可能产生额外请求。';

  @override
  String get settingsDiffViewer => '差异查看器';

  @override
  String get settingsDiffLayout => '默认差异布局';

  @override
  String get settingsDiffLayoutDescription => '选择统一或并排比较。';

  @override
  String get settingsDiffUnified => '统一';

  @override
  String get settingsDiffSplit => '并排';

  @override
  String get settingsWrapCode => '长行换行';

  @override
  String get settingsWrapCodeDescription => '将代码与差异行换行到可用宽度。';

  @override
  String get settingsLineNumbers => '显示行号';

  @override
  String get settingsLineNumbersDescription => '在代码旁显示源文件行号。';

  @override
  String get settingsDiffHighlight => '变更高亮';

  @override
  String get settingsDiffHighlightDescription => '调整新增与删除行的对比度。';

  @override
  String get settingsHighlightSubtle => '轻微';

  @override
  String get settingsHighlightDefault => '默认';

  @override
  String get settingsHighlightHigh => '高';

  @override
  String get settingsCodeFontScale => '代码文字大小';

  @override
  String get settingsCodeFontScaleDescription => '独立于界面文字缩放等宽内容。';

  @override
  String get settingsNotificationsDescription => '控制收件箱呈现和后台通知检查。';

  @override
  String get settingsInbox => '收件箱';

  @override
  String get settingsAutoMarkRead => '自动标记为已读';

  @override
  String get settingsAutoMarkReadDescription => '通知进入可见区域时将其标记为已读。';

  @override
  String get settingsGroupByRepository => '按仓库分组';

  @override
  String get settingsGroupByRepositoryDescription => '将已加载通知整理到仓库标题下。';

  @override
  String get settingsBackgroundChecks => '后台检查';

  @override
  String get settingsBackgroundChecksDescription => '后台能力取决于平台支持与操作系统权限。';

  @override
  String get settingsInboxPolling => '轮询收件箱';

  @override
  String get settingsInboxPollingDescription => '定期检查新的 GitHub 通知。';

  @override
  String get settingsPollingInterval => '轮询间隔';

  @override
  String get settingsPollingIntervalDescription => '选择后台检查收件箱的频率。';

  @override
  String settingsMinutes(int count) {
    return '$count 分钟';
  }

  @override
  String get settingsSystemNotifications => '系统通知';

  @override
  String get settingsSystemNotificationsDescription => 'DioHub 在后台时显示操作系统通知。';

  @override
  String get settingsWorkflowAlerts => '工作流运行提醒';

  @override
  String get settingsWorkflowAlertsDescription => '关注的工作流运行完成时通知。';

  @override
  String get settingsPrivacyDescription => '选择 DioHub 报告故障时可以收集哪些诊断信息。';

  @override
  String get settingsDiagnostics => '诊断';

  @override
  String get settingsDiagnosticsDescription => '诊断偏好会在下次启动应用后生效。';

  @override
  String get settingsCrashReports => '崩溃报告';

  @override
  String get settingsCrashReportsDescription => 'DioHub 崩溃时发送匿名堆栈信息。';

  @override
  String get settingsHttpDiagnostics => 'HTTP 诊断';

  @override
  String get settingsHttpDiagnosticsDescription => '包含匿名化的 API 错误模式与耗时。';

  @override
  String get settingsNavigationDiagnostics => '导航诊断';

  @override
  String get settingsNavigationDiagnosticsDescription => '包含崩溃前访问的页面顺序。';

  @override
  String get settingsPerformanceDiagnostics => '性能监控';

  @override
  String get settingsPerformanceDiagnosticsDescription => '测量响应速度与慢操作。';

  @override
  String get settingsSessionReplay => '会话回放';

  @override
  String get settingsSessionReplayDescription => '发生崩溃时记录已遮蔽的视觉轨迹。';

  @override
  String get settingsRestartRequired => '诊断设置会在下次启动应用后生效。';

  @override
  String get settingsAboutDescription => '版本、发布说明与开源致谢。';

  @override
  String get settingsApplication => '应用';

  @override
  String get settingsApplicationName => 'DioHub';

  @override
  String settingsVersion(String version, String build) {
    return '版本 $version（$build）';
  }

  @override
  String get settingsWhatsNew => '更新内容';

  @override
  String get settingsWhatsNewDescription => '查看更新日志和发布历史。';

  @override
  String get settingsOpenSourceLicenses => '开源许可证';

  @override
  String get settingsOpenSourceLicensesDescription => '查看 Flutter 与随附依赖项的许可证。';

  @override
  String get settingsAccessGroup => '访问';

  @override
  String get settingsCodePlanningAutomation => '代码、规划与自动化';

  @override
  String get settingsDioHubGroup => 'DioHub 应用设置';

  @override
  String get settingsPublicProfile => '公开资料';

  @override
  String get settingsGitHubAccount => '账户';

  @override
  String get settingsBillingAndLicensing => '账单与许可';

  @override
  String get settingsEmails => '电子邮箱';

  @override
  String get settingsPasswordAndAuthentication => '密码与身份验证';

  @override
  String get settingsSessions => '会话';

  @override
  String get settingsSshAndGpgKeys => 'SSH 与 GPG 密钥';

  @override
  String get settingsOrganizations => '组织';

  @override
  String get settingsEnterprises => '企业';

  @override
  String get settingsModeration => '内容管理';

  @override
  String get settingsCodespaces => 'Codespaces';

  @override
  String get settingsSignedOutDescription => '未登录 GitHub 时仍可使用 DioHub 应用偏好。';

  @override
  String get settingsPersonalAccount => '你的个人账户';

  @override
  String get settingsSwitchContext => '切换设置上下文';

  @override
  String get settingsPublicProfileDescription => '管理 GitHub 公开资料中显示的信息。';

  @override
  String get settingsProfileName => '姓名';

  @override
  String get settingsProfilePublicEmail => '公开邮箱';

  @override
  String get settingsProfilePublicEmailDescription => '该地址会显示在你的 GitHub 公开资料中。';

  @override
  String get settingsProfileEmailHidden => '不显示我的邮箱';

  @override
  String get settingsProfileEmailLoadError => '无法加载已验证邮箱；当前公开邮箱保持不变。';

  @override
  String get settingsProfileBio => '个人简介';

  @override
  String get settingsProfilePronouns => '代词';

  @override
  String get settingsProfileUrl => '网址';

  @override
  String get settingsProfileCompany => '公司';

  @override
  String get settingsProfileLocation => '位置';

  @override
  String get settingsProfileTwitter => 'X 用户名';

  @override
  String get settingsProfileAvailableForHire => '可接受工作机会';

  @override
  String get settingsProfilePicture => '头像';

  @override
  String get settingsManageProfilePicture => '在 GitHub 编辑';

  @override
  String get settingsUpdateProfile => '更新资料';

  @override
  String get settingsProfileUpdated => '公开资料已更新。';

  @override
  String get settingsPublicProfileLoadError => 'DioHub 无法加载此账户的公开资料。';

  @override
  String get settingsManagedByGitHub => '继续前往 GitHub';

  @override
  String get settingsBrowserOnly => 'GitHub 网页设置';

  @override
  String settingsBrowserOnlyDescription(String setting) {
    return '$setting 没有受支持的公开 API，DioHub 会打开当前服务器的对应网页。';
  }

  @override
  String get settingsPartialApiCoverage => '公开 API 仅覆盖部分功能';

  @override
  String settingsPartialApiCoverageDescription(String setting) {
    return 'GitHub 的公开 API 只覆盖 $setting 的一部分。DioHub 不会把不完整子集伪装成完整设置。';
  }

  @override
  String get settingsOAuthScopeRequired => '需要额外授权';

  @override
  String settingsOAuthScopeRequiredDescription(String setting) {
    return '$setting 有公开 API，但当前 DioHub OAuth 权限范围未授权；授权变更会单独处理。';
  }

  @override
  String settingsGitHubManagedDescription(String setting) {
    return '$setting 由 GitHub 管理。DioHub 会打开当前服务器的对应页面，不会伪造不可用的私有 API。';
  }

  @override
  String get settingsOpenOnGitHub => '在 GitHub 打开';

  @override
  String get settingsSignInToManageGitHub => '登录后才能管理此 GitHub 设置。';

  @override
  String settingsOpenOnGitHubDescription(String host) {
    return '在 $host 打开此设置。';
  }

  @override
  String get settingsCollectionLoadError => 'DioHub 无法加载此设置，请检查网络后重试。';

  @override
  String get settingsLoadMore => '加载更多';

  @override
  String get settingsRefresh => '刷新';

  @override
  String get settingsDelete => '删除';

  @override
  String get settingsEmailsDescription => '管理与 GitHub 账户关联的电子邮箱地址。';

  @override
  String get settingsAddEmail => '添加邮箱地址';

  @override
  String get settingsDeleteEmail => '删除邮箱地址';

  @override
  String settingsDeleteEmailConfirmation(String email) {
    return '从 GitHub 账户中移除 $email？';
  }

  @override
  String get settingsPrimaryEmailVisibility => '主邮箱可见性';

  @override
  String get settingsPrimaryEmailVisibilityDescription =>
      '选择是否允许在 GitHub 公开资料中显示主邮箱。';

  @override
  String get settingsNoEmails => '没有邮箱地址';

  @override
  String get settingsNoEmailsDescription => '添加一个邮箱地址以用于 GitHub 账户。';

  @override
  String get settingsEmailPrimary => '主要';

  @override
  String get settingsEmailVerified => '已验证';

  @override
  String get settingsEmailUnverified => '未验证';

  @override
  String get settingsEmailPublic => '公开';

  @override
  String get settingsEmailPrivate => '私密';

  @override
  String get settingsEmailAddress => '邮箱地址';

  @override
  String get settingsEmailInvalid => '请输入有效的邮箱地址。';

  @override
  String get settingsKeysDescription => '管理 GitHub 用于身份验证和签名验证的密钥。';

  @override
  String get settingsSshKeys => 'SSH 密钥';

  @override
  String get settingsGpgKeys => 'GPG 密钥';

  @override
  String get settingsSshSigningKeys => '签名密钥';

  @override
  String get settingsAddKey => '新建密钥';

  @override
  String get settingsDeleteKey => '删除密钥';

  @override
  String settingsDeleteKeyConfirmation(String title) {
    return '删除“$title”？此操作无法撤销。';
  }

  @override
  String get settingsNoSshKeys => '没有 SSH 密钥';

  @override
  String get settingsNoSshKeysDescription => '添加 SSH 密钥以验证 Git 操作。';

  @override
  String get settingsNoGpgKeys => '没有 GPG 密钥';

  @override
  String get settingsNoGpgKeysDescription => '添加 GPG 密钥，将支持的提交和标签标记为已验证。';

  @override
  String get settingsNoSigningKeys => '没有 SSH 签名密钥';

  @override
  String get settingsNoSigningKeysDescription => '添加 SSH 签名密钥以生成可验证的 Git 签名。';

  @override
  String settingsAddedOn(String date) {
    return '添加于 $date';
  }

  @override
  String get settingsKeyNameOptional => '名称（可选）';

  @override
  String get settingsKeyTitle => '标题';

  @override
  String get settingsArmoredGpgKey => 'ASCII 编码的 GPG 公钥';

  @override
  String get settingsPublicKey => '公钥';

  @override
  String get settingsFieldRequired => '此字段为必填项。';

  @override
  String get settingsOrganizationsDescription =>
      '查看与 GitHub 账户关联的组织；成员关系变更仍需前往 GitHub。';

  @override
  String get settingsNoOrganizations => '没有组织';

  @override
  String get settingsNoOrganizationsDescription => '此账户当前未加入任何组织。';

  @override
  String settingsOrganizationSummary(int repositories, int members) {
    return '$repositories 个仓库 · $members 名成员';
  }

  @override
  String get settingsRepositoriesDescription => '浏览此账户可访问的仓库；管理操作仍需前往 GitHub。';

  @override
  String get settingsNoRepositories => '没有仓库';

  @override
  String get settingsNoRepositoriesDescription => '此账户当前没有可访问的仓库。';

  @override
  String get settingsFork => '复刻';

  @override
  String settingsStars(int count) {
    return '$count 个星标';
  }

  @override
  String settingsUpdatedOn(String date) {
    return '更新于 $date';
  }

  @override
  String get settingsModerationDescription => '查看并管理此 GitHub 账户屏蔽的用户。';

  @override
  String get settingsBlockUser => '屏蔽用户';

  @override
  String get settingsGitHubUsername => 'GitHub 用户名';

  @override
  String get settingsBlock => '屏蔽';

  @override
  String get settingsNoBlockedUsers => '没有被屏蔽的用户';

  @override
  String get settingsNoBlockedUsersDescription => '此账户屏蔽的用户会显示在这里。';

  @override
  String get settingsUnblock => '取消屏蔽';

  @override
  String get commonLoading => '正在加载…';

  @override
  String get repoWorkflowStatusSuccess => '已成功';

  @override
  String get repoWorkflowStatusFailure => '已失败';

  @override
  String get repoWorkflowStatusTimedOut => '已超时';

  @override
  String get repoWorkflowStatusCancelled => '已取消';

  @override
  String get repoWorkflowStatusInProgress => '进行中';

  @override
  String get repoWorkflowStatusQueued => '排队中';

  @override
  String get repoWorkflowStatusWaiting => '等待中';

  @override
  String get repoWorkflowStatusPending => '待处理';

  @override
  String get repoWorkflowStatusUnknown => '未知状态';

  @override
  String get compareFileStatusAdded => '已添加';

  @override
  String get compareFileStatusRemoved => '已删除';

  @override
  String get compareFileStatusRenamed => '已重命名';

  @override
  String get compareFileStatusModified => '已修改';

  @override
  String get compareTitle => '比较';

  @override
  String get compareSelectBaseRef => '选择基准引用';

  @override
  String get compareSelectHeadRef => '选择对比引用';

  @override
  String get compareSelectBase => '选择基准…';

  @override
  String get compareSelectHead => '选择对比项…';

  @override
  String get compareSwapBaseHead => '交换基准与对比项';

  @override
  String get compareEnterRefs => '选择基准和对比引用以比较更改。';

  @override
  String compareLoadError(String error) {
    return '无法加载比较结果：$error';
  }

  @override
  String get compareAhead => '领先';

  @override
  String get compareBehind => '落后';

  @override
  String compareFilesChanged(int count) {
    return '$count 个文件已更改';
  }

  @override
  String get compareCommits => '提交';

  @override
  String get compareFiles => '文件';

  @override
  String get projectPickerLinked => '已关联';

  @override
  String get projectPickerAddToProject => '添加到项目';
}
