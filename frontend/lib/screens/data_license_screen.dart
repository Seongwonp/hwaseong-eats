import 'package:flutter/material.dart';
import '../widgets/policy_page.dart';

class DataLicenseScreen extends StatelessWidget {
  const DataLicenseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicyPage(
      title: '데이터 출처 및 라이선스',
      sections: [
        PolicySection(
          heading: '음식점 정보',
          body:
              '• 코나페이(경기지역화폐) 화성시 가맹점 정보 — search.konacard.co.kr\n'
              '• 화성시 모범음식점 현황 — 공공데이터포털(data.go.kr)\n'
              '• 전국일반음식점표준데이터 — 지방행정 인허가데이터(LOCALDATA), 공공데이터포털\n'
              '• 소상공인시장진흥공단 상가(상권)정보 — 좌표 보정용, 공공데이터포털',
        ),
        PolicySection(
          heading: '절기 · 축제 정보',
          body:
              '• 절기·명절·잡절 정보 — 한국천문연구원 특일 정보\n'
              '• 전국문화축제표준데이터 — 한국관광공사, 공공데이터포털',
        ),
        PolicySection(
          heading: '지도',
          body: '• 카카오맵 — Kakao Maps API (Kakao Corp.)',
        ),
        PolicySection(
          heading: '라이선스',
          body:
              '공공데이터포털을 통해 제공되는 데이터는 공공누리 제1유형(출처표시) 조건에 따라 이용합니다. '
              '각 원본 데이터의 저작권은 제공 기관에 있습니다.',
        ),
      ],
      footnote: '수집 시점 기준 데이터이며, 원본 제공처의 갱신 주기에 따라 실제 정보와 차이가 있을 수 있습니다.',
    );
  }
}
