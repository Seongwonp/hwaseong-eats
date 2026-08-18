import 'package:flutter/material.dart';
import '../widgets/policy_page.dart';

class LocationTermsScreen extends StatelessWidget {
  const LocationTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const PolicyPage(
      title: '위치정보 이용약관',
      sections: [
        PolicySection(
          heading: '제1조 (목적)',
          body:
              '이 약관은 볏섬(이하 "서비스")이 위치기반서비스를 제공함에 있어 이용자의 권리·의무 및 책임사항을 '
              '규정함을 목적으로 합니다.',
        ),
        PolicySection(
          heading: '제2조 (서비스 내용)',
          body:
              '서비스는 이용자의 현재 위치를 기준으로 주변 음식점을 탐색하고, 거리순 정렬 및 반경 검색을 '
              '제공합니다. 위치정보는 지도 화면 이용 시에만 일시적으로 사용되며 서버에 별도 저장하지 않습니다.',
        ),
        PolicySection(
          heading: '제3조 (개인위치정보의 이용 및 제공)',
          body:
              '서비스는 이용자의 개인위치정보를 이용자가 명시적으로 동의한 목적(주변 음식점 탐색) 범위 내에서만 '
              '이용하며, 이용자의 동의 없이 제3자에게 제공하지 않습니다.',
        ),
        PolicySection(
          heading: '제4조 (위치정보의 보유기간)',
          body: '위치정보는 지도 화면에서 검색을 수행하는 동안에만 일시적으로 처리되며 별도로 보관하지 않습니다.',
        ),
        PolicySection(
          heading: '제5조 (이용자의 권리)',
          body:
              '이용자는 위치정보 제공에 대한 동의를 언제든지 철회할 수 있으며, 기기의 위치 권한 설정을 통해 '
              '위치정보 제공을 거부할 수 있습니다. 이 경우 주변 음식점 탐색 기능 일부가 제한될 수 있습니다.',
        ),
      ],
      footnote:
          '본 화면은 해커톤 데모용으로 작성된 예시 문서이며, 위치정보의 보호 및 이용 등에 관한 법률에 따른 '
          '실제 신고·심의 절차를 거치지 않았습니다.',
    );
  }
}
