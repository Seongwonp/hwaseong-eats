import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme.dart';
import '../core/responsive.dart';
import '../providers/restaurant_provider.dart';
import '../widgets/home_restaurant_card.dart';

class NewRestaurantsScreen extends ConsumerWidget {
  const NewRestaurantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurants = newRestaurants;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          '우리집 근처 새로 오픈',
          style: TextStyle(
            fontFamily: 'NotoSerifKR',
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: restaurants.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.store_mall_directory_outlined, size: 48, color: Color(0xFFCCCCCC)),
                  SizedBox(height: 10),
                  Text('새로 오픈한 가게가 없어요', style: TextStyle(color: Colors.grey)),
                ],
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.only(top: 8, bottom: context.hp(6)),
              itemCount: restaurants.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
              itemBuilder: (_, i) => NewRestaurantCard(restaurant: restaurants[i]),
            ),
    );
  }
}
