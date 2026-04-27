import 'dart:io';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR로 인식된 상품 정보
class OcrProductResult {
  final String? productName;
  final int? originalPrice;
  final int? discountPrice;
  final String rawText;

  OcrProductResult({
    this.productName,
    this.originalPrice,
    this.discountPrice,
    this.rawText = '',
  });

  bool get hasData =>
      productName != null || originalPrice != null || discountPrice != null;

  @override
  String toString() =>
      'OcrProductResult(name: $productName, ori: $originalPrice, dis: $discountPrice)';
}

/// Google ML Kit을 사용한 상품 가격표 OCR 서비스
class OcrService {
  OcrService._();

  /// 이미지 파일에서 상품 정보를 인식합니다.
  static Future<OcrProductResult> recognizeProduct(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    // 한국어 텍스트 인식기 생성
    final textRecognizer =
        TextRecognizer(script: TextRecognitionScript.korean);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      return _parseProductInfo(recognizedText);
    } finally {
      textRecognizer.close();
    }
  }

  /// 인식된 텍스트에서 상품명, 원가, 할인가를 추출합니다.
  static OcrProductResult _parseProductInfo(RecognizedText recognizedText) {
    final rawText = recognizedText.text;
    final allLines = <_TextLineInfo>[];

    // 모든 텍스트 라인을 위치 정보와 함께 수집
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        allLines.add(_TextLineInfo(
          text: line.text.trim(),
          boundingBox: line.boundingBox,
          elements: line.elements,
        ));
      }
    }

    // 1) 가격 추출
    final prices = _extractPrices(allLines);

    // 2) 상품명 추출
    final productName = _extractProductName(allLines, prices);

    // 3) 원가/할인가 결정
    int? originalPrice;
    int? discountPrice;

    if (prices.length >= 2) {
      // 가격이 2개 이상이면 가장 큰 값 = 원가, 가장 작은 값 = 할인가
      prices.sort((a, b) => b.compareTo(a));
      originalPrice = prices[0];
      discountPrice = prices[1];
    } else if (prices.length == 1) {
      // 가격이 1개면 할인가로 설정
      discountPrice = prices[0];
    }

    return OcrProductResult(
      productName: productName,
      originalPrice: originalPrice,
      discountPrice: discountPrice,
      rawText: rawText,
    );
  }

  /// 텍스트에서 가격(숫자) 패턴을 추출합니다.
  static List<int> _extractPrices(List<_TextLineInfo> lines) {
    final prices = <int>[];

    // 가격 패턴: 숫자,숫자 형태 또는 ₩숫자 형태
    // 예: "12,735", "16,900원", "₩13,900", "5,520"
    final pricePattern = RegExp(
      r'[₩￦W]?\s*(\d{1,3}(?:[,.]?\d{3})+)\s*(?:원|₩)?|[₩￦W]\s*(\d{4,})\s*(?:원)?',
    );

    for (final line in lines) {
      final text = line.text;
      final matches = pricePattern.allMatches(text);
      for (final match in matches) {
        final raw = match.group(1) ?? match.group(2);
        if (raw != null) {
          final cleaned = raw.replaceAll(RegExp(r'[,.\s]'), '');
          final value = int.tryParse(cleaned);
          // 100원 이상, 10,000,000원 미만만 유효한 가격으로 간주
          if (value != null && value >= 100 && value < 10000000) {
            prices.add(value);
          }
        }
      }
    }

    // 중복 제거
    return prices.toSet().toList();
  }

  /// 상품명을 추출합니다.
  static String? _extractProductName(
      List<_TextLineInfo> lines, List<int> prices) {
    // 제외할 키워드 패턴
    final excludePatterns = [
      RegExp(r'^\d{4}[.\-/]\d{2}[.\-/]\d{2}'), // 날짜 (2026.04.14)
      RegExp(r'할인판매|할인상품|할인$|행사메뉴|행사$|세일'), // 프로모션
      RegExp(r'^\d+%\s*할인'), // 할인율
      RegExp(r'봄맞이|팜송오픈|오픈행사'), // 이벤트
      RegExp(r'국내산|수입산|원산지'), // 원산지
      RegExp(r'^\d+입/팩$|^\d+개$'), // 수량
      RegExp(r'까지$|기한$'), // 유통기한
      RegExp(r'^\d+[gG]$|^\d+[mM][lL]$'), // 용량
      RegExp(r'가격|정가|원가|판매가'), // 가격 라벨
      RegExp(r'바코드|\d{8,}'), // 바코드/긴 숫자
      RegExp(r'emart|이마트|PIG|GARDEN|FarmSong|KITCHEN', caseSensitive: false), // 브랜드/매장명
      RegExp(r'[A-Za-z]{5,}'), // 영어 5글자 이상 (보통 브랜드)
      RegExp(r'kcal|칼로리'), // 칼로리
      RegExp(r'소비기한|제조일자|유통'), // 날짜 관련
      RegExp(r'QR코드|스토리'), // 기타
      RegExp(r'^\s*\d+\s*$'), // 순수 숫자만
      RegExp(r'[₩￦W]\s*\d'), // 가격 표시
      RegExp(r'\d{1,3}(,\d{3})+'), // 콤마 포함 숫자 (가격)
    ];

    // 상품명 후보 수집
    final candidates = <_NameCandidate>[];

    for (final line in lines) {
      final text = line.text.trim();
      if (text.isEmpty || text.length < 2) continue;

      // 한글이 포함되어 있는지 확인
      if (!RegExp(r'[가-힣]').hasMatch(text)) continue;

      // 제외 패턴에 해당하면 스킵
      bool excluded = false;
      for (final pattern in excludePatterns) {
        if (pattern.hasMatch(text)) {
          excluded = true;
          break;
        }
      }
      if (excluded) continue;

      // 한글 글자 수 계산
      final koreanChars = RegExp(r'[가-힣]').allMatches(text).length;
      if (koreanChars < 2) continue;

      // 점수 계산: 한글 비율이 높고, 적절한 길이(2~15자)일수록 높은 점수
      double score = koreanChars.toDouble();

      // 글자 크기(bounding box 높이)가 클수록 제목일 가능성 높음
      final height = line.boundingBox.height;
      score += height * 0.1;

      // 너무 긴 텍스트는 감점 (설명문일 가능성)
      if (text.length > 20) score -= 5;

      // "NEW", "신제품" 등이 포함되어 있으면 약간 감점
      if (RegExp(r'NEW|신제품|신상').hasMatch(text)) score -= 3;

      candidates.add(_NameCandidate(
        text: text,
        score: score,
        y: line.boundingBox.top,
      ));
    }

    if (candidates.isEmpty) return null;

    // 점수가 가장 높은 후보 선택
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return _cleanProductName(candidates.first.text);
  }

  /// 상품명 정리 (불필요한 문자 제거)
  static String _cleanProductName(String name) {
    // 앞뒤 공백, 특수문자 제거
    var cleaned = name.trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[^\w가-힣]+|[^\w가-힣]+$'), '');

    // "피그인더가든" 같은 브랜드명 다음의 상품명만 추출
    // (하위 라인에서 이미 걸러지지만, 혹시 합쳐진 경우)
    if (cleaned.length > 15) {
      // 너무 긴 경우 첫 15자까지만
      cleaned = cleaned.substring(0, 15);
    }

    return cleaned.isEmpty ? name.trim() : cleaned;
  }
}

/// 텍스트 라인 정보
class _TextLineInfo {
  final String text;
  final Rect boundingBox;
  final List<TextElement> elements;

  _TextLineInfo({
    required this.text,
    required this.boundingBox,
    required this.elements,
  });
}

/// 상품명 후보
class _NameCandidate {
  final String text;
  final double score;
  final double y; // Y 위치

  _NameCandidate({
    required this.text,
    required this.score,
    required this.y,
  });
}
