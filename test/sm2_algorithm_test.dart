import 'package:flutter_test/flutter_test.dart';
import 'package:wordwise/features/study/domain/usecases/sm2_algorithm.dart';

void main() {
  group('SM-2 算法测试', () {
    test('评分 5（完美记住）应该延长间隔', () {
      // 第一次学习，评分 5
      var result = Sm2Algorithm.calculate(
        quality: 5,
        currentInterval: 1,
        currentEaseFactor: 2.5,
        reviewCount: 0,
      );

      // 第一次学习间隔应该是 1
      expect(result.newInterval, 1);
      // 复习次数变为 1
      expect(result.newReviewCount, 1);
    });

    test('评分 0（完全忘记）应该重置间隔为 1', () {
      var result = Sm2Algorithm.calculate(
        quality: 0,
        currentInterval: 10,
        currentEaseFactor: 2.5,
        reviewCount: 5,
      );

      expect(result.newInterval, 1);
    });

    test('评分 3（勉强记住）间隔应该略微延长', () {
      var result = Sm2Algorithm.calculate(
        quality: 3,
        currentInterval: 6,
        currentEaseFactor: 2.5,
        reviewCount: 2,
      );

      // 第3次复习，间隔 = 6 * 2.5 = 15
      expect(result.newInterval, 14);
    });

    test('难易度因子不应该低于 1.3', () {
      var result = Sm2Algorithm.calculate(
        quality: 0,
        currentInterval: 1,
        currentEaseFactor: 2.5,
        reviewCount: 0,
      );

      // 评分 0 会降低 EF，但不低于 1.3
      expect(result.newEaseFactor >= 1.3, true);
    });

    test('间隔不应该超过 365 天', () {
      // 模拟一个已经复习很多次、EF 很高的单词
      var result = Sm2Algorithm.calculate(
        quality: 5,
        currentInterval: 300,
        currentEaseFactor: 2.5,
        reviewCount: 10,
      );

      // 最大间隔不超过 365
      expect(result.newInterval <= 365, true);
    });
  });
}