import 'dart:io';
import 'dart:ui';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;

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
    // 바비큐/폭립 계열 (받침·획 오인식이 잦음)
    '바큐': '바비큐',
    '쪽립': '폭립',
    '쪽갈비': '폭갈비',
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
      final base = _parseProductInfo(recognizedText);

      // DELI류 가격표(손글씨 할인가 + 취소선 정가)는 가격칸만 크롭·확대해
      // 다시 인식하면 정가/할인가 분리 정확도가 크게 올라갑니다.
      final cellPrices = await _recognizePriceCell(
        imageFile,
        recognizedText,
        textRecognizer,
      );
      if (cellPrices != null && cellPrices.isNotEmpty) {
        return _mergeCellPrices(base, cellPrices, recognizedText);
      }

      return base;
    } finally {
      textRecognizer.close();
    }
  }

  /// 전체 인식 결과(base)에 가격칸 정밀 인식 결과(cellPrices)를 합칩니다.
  /// 가격칸에서 2개를 얻으면 큰 값=정가, 작은 값=할인가로 덮어씁니다.
  static OcrProductResult _mergeCellPrices(
    OcrProductResult base,
    List<int> cellPrices,
    RecognizedText fullText,
  ) {
    int? originalPrice = base.originalPrice;
    int? discountPrice = base.discountPrice;

    final sorted = [...cellPrices]..sort();
    if (sorted.length >= 2) {
      // 가격칸에 두 값 → 큰 값=정가(취소선), 작은 값=할인가(손글씨)
      final lo = sorted.first;
      final hi = sorted.last;
      discountPrice = lo;
      // 정상적인 할인 비율(작은값/큰값 = 0.3~0.98)일 때만 가격칸 결과로
      // 정가를 덮어쓴다. 비율이 비정상이면(오인식) 정가는 전체 인식 결과를 신뢰.
      final ratio = lo / hi;
      if (ratio >= 0.3 && ratio <= 0.98) {
        originalPrice = hi;
      } else if (base.originalPrice != null && base.originalPrice! > lo) {
        originalPrice = base.originalPrice;
      } else {
        originalPrice = hi;
      }
    } else {
      // 가격칸에 한 값만 → 할인가로 채택
      discountPrice = sorted.first;
      // 기존 정가가 할인가보다 작거나 같으면(오인식) 비움
      if (originalPrice != null && originalPrice <= discountPrice) {
        originalPrice = null;
      }
    }

    return OcrProductResult(
      productName: base.productName,
      originalPrice: originalPrice,
      discountPrice: discountPrice,
      rawText: base.rawText,
    );
  }

  /// 가격표의 '가격(원)' 칸 영역만 잘라내 확대·전처리 후 다시 OCR합니다.
  /// 손글씨 할인가와 취소선 그어진 정가가 한 덩어리로 붙어 읽히는 문제를
  /// 완화하기 위한 전처리입니다. 가격 라벨을 못 찾으면 null을 반환합니다.
  static Future<List<int>?> _recognizePriceCell(
    File imageFile,
    RecognizedText fullText,
    TextRecognizer recognizer,
  ) async {
    // 1) '가격(원)' 라벨 위치 탐색 (DELI류 가격표의 우측 가격칸 헤더)
    Rect? priceLabel;
    for (final block in fullText.blocks) {
      for (final line in block.lines) {
        final t = line.text.replaceAll(' ', '');
        // "가격(원)" / "가격" 헤더. 가격칸 헤더가 아닌 본문 '가격'은 드묾.
        if (RegExp(r'가격\(?원?\)?$|^가격$').hasMatch(t)) {
          priceLabel = line.boundingBox;
        }
      }
    }
    if (priceLabel == null) return null;

    // 2) 이미지 디코드
    final img.Image? decoded = img.decodeImage(await imageFile.readAsBytes());
    if (decoded == null) return null;
    final int w = decoded.width;
    final int h = decoded.height;

    // 3) 크롭 영역 계산
    //    가로: 라벨 왼쪽으로 라벨폭의 1.3배까지 확장(손글씨 할인가가 헤더보다
    //          왼쪽에 적히는 경우 포함) ~ 이미지 우측 끝
    //    세로: 라벨 위 ~ 이미지 하단(가격 숫자는 헤더 아래에 위치)
    final int marginX = (priceLabel.width * 1.3).round();
    int left = (priceLabel.left.round() - marginX).clamp(0, w - 1);
    int top = priceLabel.top.round().clamp(0, h - 1);
    int cropW = (w - left).clamp(1, w);
    int cropH = (h - top).clamp(1, h);
    if (cropW < 20 || cropH < 20) return null;

    // 4) 크롭 → 2배 확대 → 그레이스케일 → 대비 강화
    img.Image crop = img.copyCrop(
      decoded,
      x: left,
      y: top,
      width: cropW,
      height: cropH,
    );
    crop = img.copyResize(
      crop,
      width: cropW * 2,
      height: cropH * 2,
      interpolation: img.Interpolation.cubic,
    );
    crop = img.grayscale(crop);
    crop = img.adjustColor(crop, contrast: 1.4);

    // 5) 임시 파일로 저장 후 가격칸만 다시 OCR
    final String tmpPath =
        '${imageFile.parent.path}/.ocr_price_cell_${imageFile.uri.pathSegments.last}.png';
    final File tmpFile = File(tmpPath);
    List<int> values;
    try {
      await tmpFile.writeAsBytes(img.encodePng(crop));
      final cellText = await recognizer.processImage(
        InputImage.fromFile(tmpFile),
      );
      values = _pricesFromText(cellText);
    } finally {
      try {
        if (await tmpFile.exists()) await tmpFile.delete();
      } catch (_) {}
    }
    return values.isEmpty ? null : values;
  }

  /// 인식된(가격칸) 텍스트에서 유효 가격 숫자만 뽑아 반환합니다.
  static List<int> _pricesFromText(RecognizedText text) {
    final found = <int>{};
    final pattern = RegExp(r'\d{1,3}(?:[,.]\d{3})+|\d{3,6}');
    final strike = RegExp(r'[ㅡ─━—–\-]+');
    for (final block in text.blocks) {
      for (final line in block.lines) {
        for (final el in line.elements) {
          final cleaned = el.text.replaceAll(strike, '');
          for (final m in pattern.allMatches(cleaned)) {
            final v = int.tryParse(m.group(0)!.replaceAll(RegExp(r'[,.]'), ''));
            // 가격칸이므로 천원~10만원 미만만 인정.
            // 6자리 이상(>=100,000)은 손글씨 할인가+취소선 정가+바코드 잔재가
            // 한 숫자로 붙어 읽힌 오인식(예: '4790'+'5990'→479059)일 확률이
            // 높아 가격 후보에서 제외한다.
            if (v != null && v >= 1000 && v < 100000) found.add(v);
          }
        }
      }
    }
    return found.toList();
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
    final priceResult = _extractPrices(allLines, allElements);

    // 2) 상품명 추출
    final productName = _extractProductName(allLines);

    // 3) 원가/할인가 결정
    int? originalPrice;
    int? discountPrice;

    if (priceResult.rangeOriginal != null &&
        priceResult.rangeDiscount != null) {
      // "9,990 → 6,993" 처럼 한 라인에서 정가→할인가 쌍을 직접 찾은 경우 최우선
      originalPrice = priceResult.rangeOriginal;
      discountPrice = priceResult.rangeDiscount;
    } else {
      final prices = priceResult.prices;
      if (prices.length >= 2) {
        // 가격이 2개 이상이면 가장 큰 값 = 원가, 가장 작은 값 = 할인가
        prices.sort((a, b) => b.compareTo(a));
        originalPrice = prices[0];
        discountPrice = prices[1];
      } else if (prices.length == 1) {
        // 가격이 1개면 할인가로 설정
        discountPrice = prices[0];
      }
    }

    return OcrProductResult(
      productName: productName,
      originalPrice: originalPrice,
      discountPrice: discountPrice,
      rawText: rawText,
    );
  }

  /// 가격표에서 가격이 아닌 숫자가 섞여 있는 라인(품번/바코드/날짜 등)을
  /// 판별합니다. 이런 라인은 가격 매칭에서 제외해야 정가/할인가 오인식을 막습니다.
  static bool _isNonPriceLine(String text) {
    // 품번/품목코드/상품코드 — "품번:605,224" 같은 6자리 숫자가 정가로 오인식됨
    if (RegExp(r'품\s*번|품\s*목|상품\s*코드|바\s*코\s*드').hasMatch(text)) {
      return true;
    }
    // 8자리 이상 연속 숫자 = 바코드
    if (RegExp(r'\d{8,}').hasMatch(text)) return true;
    // 공백으로 구분된 숫자 그룹이 3개 이상 = 바코드 숫자열
    // (예: "01028 61260 00000 53000")
    if (RegExp(r'\d{3,}').allMatches(text).length >= 3) return true;
    // 발행일/제조일 등 날짜 안내 라인
    if (RegExp(r'발행일|제조일|소비기한|유통기한').hasMatch(text)) return true;
    return false;
  }

  /// 텍스트에서 가격(숫자) 패턴을 추출합니다.
  /// 취소선/대시 등의 노이즈는 제거 후 매칭하고,
  /// 품번/바코드 라인은 건너뛰며, "정가 → 할인가" 한 라인 쌍을 우선 인식합니다.
  static _PriceResult _extractPrices(
    List<_TextLineInfo> lines,
    List<_ElementInfo> elements,
  ) {
    final priceSet = <int>{};
    int? rangeOriginal;
    int? rangeDiscount;

    // 콤마/마침표 천단위 구분형(9,990) 또는 구분자 없는 4~6자리(4790)
    final pricePattern = RegExp(r'\d{1,3}(?:[,.]\d{3})+|\d{4,6}');

    String stripStrike(String s) {
      // 취소선이 OCR에 섞여 들어오는 경우(대시 종류, 가운데줄 등)와
      // 한글 자모 'ㅡ'(가로획)도 함께 제거
      return s.replaceAll(RegExp(r'[ㅡ─━—–\-]+'), '');
    }

    int? toPrice(String raw) {
      final cleaned = raw.replaceAll(RegExp(r'[,.\s]'), '');
      final value = int.tryParse(cleaned);
      // 500원 이상, 1,000,000원 미만만 유효한 가격으로 간주
      if (value != null && value >= 500 && value < 1000000) return value;
      return null;
    }

    // 1) 라인 단위 매칭
    for (final line in lines) {
      if (_isNonPriceLine(line.text)) continue;
      final cleaned = stripStrike(line.text);

      // 한 라인에서 발견된 가격들(중복 제거, 순서 유지)
      final lineValues = <int>[];
      for (final m in pricePattern.allMatches(cleaned)) {
        final v = toPrice(m.group(0)!);
        if (v != null) {
          priceSet.add(v);
          if (!lineValues.contains(v)) lineValues.add(v);
        }
      }

      // "9,990 → 6,993" / "4,990 3,493" 처럼 한 라인에 정가·할인가가 함께 있고
      // 큰 값/작은 값 비율이 자연스러운 할인 범위면 정가→할인가 쌍으로 채택
      if (rangeOriginal == null && lineValues.length >= 2) {
        final sorted = [...lineValues]..sort((a, b) => b.compareTo(a));
        final hi = sorted[0];
        final lo = sorted[1];
        final ratio = lo / hi;
        if (hi != lo && ratio >= 0.4 && ratio <= 0.97) {
          rangeOriginal = hi;
          rangeDiscount = lo;
        }
      }
    }

    // 2) 라인 단위에서 가격이 부족하면 element 단위로도 매칭
    //    (취소선이 라인을 토막내서 정상 가격 라인이 누락되는 경우 대비)
    if (priceSet.length < 2 && rangeOriginal == null) {
      final elementPattern = RegExp(r'^(\d{1,3}[,.]\d{3}|\d{4,6})$');
      for (final el in elements) {
        final cleaned = stripStrike(el.text);
        final m = elementPattern.firstMatch(cleaned);
        if (m != null) {
          final v = toPrice(m.group(1)!);
          if (v != null) priceSet.add(v);
        }
      }
    }

    // 3) 6자리 이상(10만원~) 숫자는 품번/바코드 잔재일 가능성이 높음 →
    //    더 작은 정상 가격이 존재하면 큰 숫자는 가격 후보에서 제외
    var prices = priceSet.toList();
    final hasSmall = prices.any((p) => p < 100000);
    if (hasSmall) {
      prices = prices.where((p) => p < 100000).toList();
    }

    return _PriceResult(
      prices,
      rangeOriginal: rangeOriginal,
      rangeDiscount: rangeDiscount,
    );
  }

  /// 상품명을 추출합니다.
  static String? _extractProductName(List<_TextLineInfo> lines) {
    // 제외할 키워드 패턴
    final excludePatterns = [
      RegExp(r'^\d{4}[.\-/]\d{2}[.\-/]\d{2}'), // 날짜 (2026.04.14)
      RegExp(r'^\d{2}[.\-/]\d{2}[.\-/]\d{2}'), // 날짜 (26.04.23)
      RegExp(r'할인|행사|세일|봄맞이|팜송오픈|오픈행사|제외|증정|사은품'), // 프로모션/할인 스티커 (예: '할인싱', '할인 제외')
      RegExp(r'\d\s*%'), // '%'가 포함된 라인(예: '30% 활별발한')은 할인 스티커 → 상품명 아님
      RegExp(r'품\s*번|품\s*목|상품\s*코드|발행일'), // 품번/품목코드
      RegExp(r'\d{4,}'), // 4자리 이상 숫자가 섞인 라인(가격/바코드/프로모션) → 상품명 아님
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

      // 정규화된 글자 크기 — 상품명은 보통 큰 글씨 중 하나.
      // 단, 할인 스티커('30%', '할인상품')가 상품명보다 더 크게 인쇄되는
      // 경우가 많아 높이 가중치를 과도하게 주지 않는다.
      if (maxHeight > 0) {
        final relHeight = line.boundingBox.height / maxHeight;
        score += relHeight * 8;
      }

      // 한글 글자 수가 많을수록 실제 상품명일 가능성이 높음.
      // (할인 스티커 잔재는 '할인싱', '채외'처럼 짧은 조각인 경우가 많음)
      score += koreanChars.clamp(0, 10) * 1.2;
      if (koreanChars <= 3) score -= 3;

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
    var cleaned = name.trim();
    // 앞뒤의 군더더기 기호만 제거하되, 상품명의 일부인 괄호 '()[]'와
    // 슬래시 '/'는 보존한다.
    //   예) '볼케이노오븐구이치킨(마리)'  → 끝의 ')' 유지
    //       '반반김밥(불고기/참치)'      → '(', '/', ')' 모두 유지
    cleaned = cleaned.replaceAll(RegExp(r'^[^\w가-힣(\[]+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[^\w가-힣)\]]+$'), '');

    // 너무 긴 경우 첫 20자까지만
    if (cleaned.length > 20) {
      cleaned = cleaned.substring(0, 20);
    }

    return cleaned.isEmpty ? name.trim() : cleaned;
  }
}

/// 가격 추출 결과
/// - [prices]: 라인/요소에서 수집한 가격 후보들
/// - [rangeOriginal]/[rangeDiscount]: "9,990 → 6,993"처럼 한 라인에서
///   직접 얻은 정가/할인가 쌍(있으면 최우선 사용)
class _PriceResult {
  final List<int> prices;
  final int? rangeOriginal;
  final int? rangeDiscount;

  _PriceResult(this.prices, {this.rangeOriginal, this.rangeDiscount});
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
