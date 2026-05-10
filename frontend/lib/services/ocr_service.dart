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

  /// 한국 식품/상품명에서 자주 발생하는 OCR 오인식 보정 맵.
  /// (받침 'ㅁ' → 'ㄹ' 또는 유사 글리프 오인식이 잦음)
  static final Map<String, String> _foodNameCorrections = {
    // 볶음 계열 (받침 ㅁ → ㄹ/기타 오인식)
    '볶을': '볶음',
    '볶룸': '볶음',
    '볶륜': '볶음',
    '볶훔': '볶음',
    // 무침 계열
    '무칠': '무침',
    '무친': '무침',
    // 비빔 계열
    '비빔을': '비빔음',
    // 조림 끝에 조사 '을'이 붙는 형태는 상품명에서 부적절 → 정리
    '조림을': '조림',
    '구이를': '구이',
    '구이을': '구이',
  };

  /// 성분표/원산지 표시에 자주 등장하는 패턴 — 상품명 후보에서 강한 감점
  static final List<RegExp> _ingredientHints = [
    // 괄호 안 원산지 ("(러시아)", "(미국산)" 등)
    RegExp(
      r'\([^)]*?(러시아|미국|중국|호주|인도|외국|국내|뉴질랜드|일본|베트남|태국|칠레|페루|노르웨이|덴마크|네덜란드|독일|에콰도르)[^)]*?\)',
    ),
    RegExp(r'\([^)]{0,4}산\s*\)'),
    RegExp(r'밀:|쌀:|콩:|매미노산|아미노산|탈지대두|소맥분|혼합간장|원산지|첨가물'),
  ];

  /// 이미지 파일에서 상품 정보를 인식합니다.
  static Future<OcrProductResult> recognizeProduct(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);

    // 한국어 텍스트 인식기 생성
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.korean);

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
    final allElements = <_ElementInfo>[];

    // 모든 텍스트 라인/요소를 위치 정보와 함께 수집
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        allLines.add(
          _TextLineInfo(
            text: line.text.trim(),
            boundingBox: line.boundingBox,
            elements: line.elements,
          ),
        );
        for (final el in line.elements) {
          allElements.add(
            _ElementInfo(text: el.text.trim(), boundingBox: el.boundingBox),
          );
        }
      }
    }

    // 1) 가격 추출 (라인 단위 → 부족하면 element 단위로 보강)
    final prices = _extractPrices(allLines, allElements);

    // 2) 상품명 추출
    final productName = _extractProductName(allLines);

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
  /// 취소선/대시 등의 노이즈는 제거 후 매칭하고,
  /// 라인 단위 결과가 빈약하면 element 단위로 한 번 더 시도합니다.
  static List<int> _extractPrices(
    List<_TextLineInfo> lines,
    List<_ElementInfo> elements,
  ) {
    final priceSet = <int>{};

    final pricePattern = RegExp(r'(\d{1,3}(?:[,.\s]?\d{3})+)\s*(?:원|₩|￦)?');

    String stripStrike(String s) {
      // 취소선이 OCR에 섞여 들어오는 경우(대시 종류, 가운데줄 등)와
      // 한글 자모 'ㅡ'(가로획)도 함께 제거
      return s.replaceAll(RegExp(r'[ㅡ─━—–\-]+'), '');
    }

    bool addIfValid(String? raw) {
      if (raw == null) return false;
      final cleaned = raw.replaceAll(RegExp(r'[,.\s]'), '');
      final value = int.tryParse(cleaned);
      // 500원 이상, 1,000,000원 미만만 유효한 가격으로 간주
      if (value != null && value >= 500 && value < 1000000) {
        priceSet.add(value);
        return true;
      }
      return false;
    }

    // 1) 라인 단위 매칭
    for (final line in lines) {
      final cleaned = stripStrike(line.text);
      for (final m in pricePattern.allMatches(cleaned)) {
        addIfValid(m.group(1));
      }
    }

    // 2) 라인 단위에서 가격이 부족하면 element 단위로도 매칭
    //    (취소선이 라인을 토막내서 정상 가격 라인이 누락되는 경우 대비)
    if (priceSet.length < 2) {
      final elementPattern = RegExp(
        r'^(\d{1,3}[,.\s]\d{3})\s*(?:원)?$|^(\d{4,6})\s*(?:원)?$',
      );
      for (final el in elements) {
        final cleaned = stripStrike(el.text);
        final m = elementPattern.firstMatch(cleaned);
        if (m != null) {
          addIfValid(m.group(1) ?? m.group(2));
        }
      }
    }

    return priceSet.toList();
  }

  /// 상품명을 추출합니다.
  static String? _extractProductName(List<_TextLineInfo> lines) {
    // 제외할 키워드 패턴
    final excludePatterns = [
      RegExp(r'^\d{4}[.\-/]\d{2}[.\-/]\d{2}'), // 날짜 (2026.04.14)
      RegExp(r'^\d{2}[.\-/]\d{2}[.\-/]\d{2}'), // 날짜 (26.04.23)
      RegExp(r'할인판매|할인상품|할인$|행사메뉴|행사$|세일|봄맞이|팜송오픈|오픈행사'), // 프로모션
      RegExp(r'^\d+%\s*할인'), // 할인율
      RegExp(r'국내산|수입산|원산지'), // 원산지
      RegExp(r'^\d+입/팩$|^\d+개$'), // 수량
      RegExp(r'까지$|기한$|소비기한|제조일자|유통'), // 유통기한 관련
      RegExp(r'^\d+[gG]$|^\d+[mM][lL]$'), // 용량
      RegExp(r'가격|정가|원가|판매가'), // 가격 라벨
      RegExp(r'바코드|\d{8,}'), // 바코드/긴 숫자
      RegExp(
        r'emart|이마트|PIG|GARDEN|FarmSong|KITCHEN|KIM|CLUB',
        caseSensitive: false,
      ), // 브랜드/매장명
      RegExp(r'kcal|칼로리'), // 칼로리
      RegExp(r'QR코드|스토리'), // 기타
      RegExp(r'^\s*\d+\s*$'), // 순수 숫자만
      RegExp(r'^\s*[₩￦W]\s*\d'), // 가격 표시
      RegExp(r'^\s*\d{1,3}([,.]\d{3})+\s*원?\s*$'), // 가격 한 줄
      RegExp(r'보관방법|냉장보관|냉동보관'), // 보관 안내
      RegExp(r'\d+\s*℃|이하\s*냉'), // 보관 온도
    ];

    // 가장 큰 라인 높이(제목 후보 식별을 위한 정규화 기준)
    double maxHeight = 0;
    for (final line in lines) {
      final h = line.boundingBox.height;
      if (h > maxHeight) maxHeight = h;
    }

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

      double score = 0;

      // 한글 비율 (성분표는 영문/숫자/괄호가 섞이므로 한글 비율이 떨어짐)
      final koreanRatio = koreanChars / text.length;
      score += koreanRatio * 5;

      // 정규화된 글자 크기 — 상품명은 보통 가장 큰 글씨 중 하나
      if (maxHeight > 0) {
        final relHeight = line.boundingBox.height / maxHeight;
        score += relHeight * 12;
      }

      // 적절한 길이(3~12자)에 가점, 너무 길면 강한 감점
      if (text.length >= 3 && text.length <= 12) {
        score += 3;
      } else if (text.length > 20) {
        score -= 10;
      } else if (text.length > 15) {
        score -= 4;
      }

      // 성분표/원산지 패턴은 강한 감점
      for (final p in _ingredientHints) {
        if (p.hasMatch(text)) {
          score -= 12;
          break;
        }
      }

      // 콤마/괄호가 다수 포함된 라인은 성분표 가능성이 높음
      final commaCount = ','.allMatches(text).length;
      if (commaCount >= 2) score -= 6;
      final parenCount = '('.allMatches(text).length;
      if (parenCount >= 2) score -= 6;

      // NEW/신상은 약한 감점
      if (RegExp(r'NEW|신제품|신상').hasMatch(text)) score -= 1;

      candidates.add(
        _NameCandidate(text: text, score: score, y: line.boundingBox.top),
      );
    }

    if (candidates.isEmpty) return null;

    // 점수가 가장 높은 후보 선택 후 OCR 오인식 보정 + 정리
    candidates.sort((a, b) => b.score.compareTo(a.score));
    return _cleanProductName(_correctKoreanOcr(candidates.first.text));
  }

  /// 한국 식품명에서 자주 발생하는 OCR 오인식을 보정합니다.
  /// 예: '오징어볶을' → '오징어볶음'
  static String _correctKoreanOcr(String text) {
    var result = text;
    _foodNameCorrections.forEach((wrong, right) {
      result = result.replaceAll(wrong, right);
    });
    return result;
  }

  /// 상품명 정리 (불필요한 문자 제거)
  static String _cleanProductName(String name) {
    // 앞뒤 공백, 특수문자 제거
    var cleaned = name.trim();
    cleaned = cleaned.replaceAll(RegExp(r'^[^\w가-힣]+|[^\w가-힣]+$'), '');

    // 너무 긴 경우 첫 15자까지만
    if (cleaned.length > 15) {
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

/// 텍스트 요소(단어) 정보 — 라인보다 작은 단위
class _ElementInfo {
  final String text;
  final Rect boundingBox;

  _ElementInfo({required this.text, required this.boundingBox});
}

/// 상품명 후보
class _NameCandidate {
  final String text;
  final double score;
  final double y; // Y 위치

  _NameCandidate({required this.text, required this.score, required this.y});
}
