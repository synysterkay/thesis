// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get welcome => '专业学术论文';

  @override
  String get onboardDescription1 => '使用AI辅助创建专业学术论文';

  @override
  String get smartContent => '智能内容生成';

  @override
  String get onboardDescription2 => '自动生成结构完善的章节和内容';

  @override
  String get onboardDescription3 => '以专业PDF格式导出论文';

  @override
  String get easyExport => '轻松PDF导出';

  @override
  String get next => '下一步';

  @override
  String get getStarted => '开始使用';

  @override
  String get startWritingHere => '在此开始写作...';

  @override
  String get reportContent => '报告内容';

  @override
  String get unsavedChanges => '未保存的更改';

  @override
  String get saveChangesQuestion => '是否要保存更改？';

  @override
  String get discard => '放弃';

  @override
  String get save => '保存';

  @override
  String get reportContentIssue => '请描述此内容的问题：';

  @override
  String get enterConcern => '输入您的问题...';

  @override
  String get cancel => '取消';

  @override
  String get submit => '提交';

  @override
  String get reportSubmitted => '报告提交成功';

  @override
  String get changesSaved => '更改已保存';

  @override
  String get initializationError => '初始化错误';

  @override
  String get retry => '重试';

  @override
  String get exportThesis => '导出论文';

  @override
  String get exportAsPdf => '导出为PDF';

  @override
  String get exportDescription => '您的论文将以PDF格式导出并保存到下载文件夹。';

  @override
  String pdfSavedToDownloads(String path) {
    return 'PDF已保存到下载文件夹：$path';
  }

  @override
  String get ok => '确定';

  @override
  String error(String message) {
    return '错误：$message';
  }

  @override
  String get thesis => '论文';

  @override
  String get generateAll => '生成全部';

  @override
  String get pleaseCompleteAllSections => '导出前请完成所有部分';

  @override
  String get generatedSuccessfully => '生成成功！点击PDF进行导出';

  @override
  String errorGeneratingContent(Object error) {
    return '生成内容时出错：$error';
  }

  @override
  String failedToGenerateContent(Object error) {
    return '内容生成失败：$error';
  }

  @override
  String get loadingMessage1 => '正在生成论文结构...';

  @override
  String get loadingMessage2 => '此过程需要约4-7分钟...';

  @override
  String get loadingMessage3 => '正在规划您的学术旅程...';

  @override
  String get loadingMessage4 => '正在组织研究框架...';

  @override
  String get loadingMessage5 => '正在为您的论文建立坚实基础...';

  @override
  String get loadingMessage6 => '即将完成，正在最终确定大纲...';

  @override
  String get createThesis => '创建论文';

  @override
  String get thesisTopic => '论文主题';

  @override
  String get enterThesisTopic => '输入论文主题';

  @override
  String get pleaseEnterTopic => '请输入主题';

  @override
  String get generateChapters => '生成章节';

  @override
  String get generatedChapters => '已生成的章节';

  @override
  String chapter(Object number) {
    return '第$number章';
  }

  @override
  String get pleaseEnterChapterTitle => '请输入章节标题';

  @override
  String get writingStyle => '写作风格';

  @override
  String get format => '格式';

  @override
  String get generateThesis => '生成论文';

  @override
  String get pleaseEnterThesisTopicFirst => '请先输入论文主题';

  @override
  String failedToGenerateChapters(Object error) {
    return '生成章节失败：$error';
  }

  @override
  String errorGeneratingThesis(Object error) {
    return '生成论文时出错：$error';
  }

  @override
  String get generatingContent => '正在生成内容...';

  @override
  String get pleaseCompleteAllChapters => '请完成所有章节标题';

  @override
  String get requiredChaptersMissing => '引言和结论章节为必需章节';

  @override
  String get openFile => '打开文件';

  @override
  String get errorGeneratingOutlines => '生成大纲时出错';

  @override
  String get edit => '编辑';

  @override
  String get addText => '添加文本';

  @override
  String get highlight => '高亮';

  @override
  String get delete => '删除';

  @override
  String get savePdf => '保存PDF';

  @override
  String get share => '分享';

  @override
  String get thesisOutline => '论文大纲';
}
