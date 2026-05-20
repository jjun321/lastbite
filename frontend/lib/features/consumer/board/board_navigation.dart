import 'package:flutter/foundation.dart';

/// 제보게시판 탭으로 진입할 때 함께 전달되는 필터 정보.
class ReportBoardFilter {
  final int? storeId;
  final String? storeName;
  final int? productId;
  final String? productName;

  const ReportBoardFilter({
    this.storeId,
    this.storeName,
    this.productId,
    this.productName,
  });
}

/// 외부 화면(예: 매장정보의 제보 카드)에서 제보게시판 탭으로 이동하면서
/// 필터를 같이 넘기기 위한 단순 글로벌 알림 채널.
class BoardNavigation {
  /// 제보게시판 탭에서 적용해야 할 다음 필터.
  /// 적용 후에는 ReportBoardPage 가 직접 null 로 비운다.
  static final ValueNotifier<ReportBoardFilter?> pendingFilter =
      ValueNotifier(null);

  /// ConsumerHomePage 가 현재 탭을 강제로 바꾸기 위한 신호.
  /// 값이 바뀔 때마다 ConsumerHomePage 가 setState 로 탭을 전환한다.
  static final ValueNotifier<int> requestedTabIndex = ValueNotifier(0);

  /// 필터와 탭 전환을 한 번에 트리거하는 헬퍼.
  static void openReportBoard({ReportBoardFilter? filter}) {
    pendingFilter.value = filter;
    requestedTabIndex.value = 1;
  }
}
