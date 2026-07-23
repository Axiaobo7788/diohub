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
}
