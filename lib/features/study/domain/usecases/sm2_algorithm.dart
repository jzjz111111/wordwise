/// SM-2 间隔重复算法
/// 参考论文：https://www.supermemo.com/english/ol/sm2
class Sm2Algorithm {
  /// 计算复习结果
  /// [quality] 用户自评质量：0-5
  ///   - 5: 完美记住
  ///   - 4: 正确但犹豫
  ///   - 3: 勉强正确
  ///   - 2: 错了，但想起来
  ///   - 1: 完全忘记
  ///   - 0: 完全空白
  /// [currentInterval] 当前间隔（天）
  /// [currentEaseFactor] 当前难易度因子
  /// [reviewCount] 已复习次数
  /// 返回： (新间隔, 新难易度因子, 新复习次数)
  /// 元组，方法返回多个值
  /// required强调使用时必须传入该参数
  /// 算法纯函数，不依赖外部状态，用static可以直接调用，避免不必要的对象创建
  static ({int newInterval, double newEaseFactor, int newReviewCount}) calculate({
    required int quality,
    required int currentInterval,
    required double currentEaseFactor,
    required int reviewCount,
  }) {
    // 1. 参数校验
    if (quality < 0 || quality > 5) {
      throw ArgumentError('quality 必须在 0-5 之间');
      // dart内置异常，表示传入的参数不合法
    }
    if (currentInterval < 1) {
      throw ArgumentError('currentInterval 必须 >= 1');
    }
    if (currentEaseFactor < 1.3) {
      throw ArgumentError('currentEaseFactor 必须 >= 1.3');
    }
    if (reviewCount < 0) {
      throw ArgumentError('reviewCount 必须 >= 0');
    }

    // 2. 计算新的难易度因子
    double newEaseFactor = _calculateEaseFactor(
      quality: quality,
      currentEaseFactor: currentEaseFactor,
    );

    // 3. 计算新的间隔
    int newInterval = _calculateInterval(
      quality: quality,
      currentInterval: currentInterval,
      easeFactor: newEaseFactor,
      reviewCount: reviewCount,
    );

    // 4. 复习次数 +1
    int newReviewCount = reviewCount + 1;

    return (
    newInterval: newInterval,
    newEaseFactor: newEaseFactor,
    newReviewCount: newReviewCount,
    );
  }

  /// 计算新的难易度因子
  static double _calculateEaseFactor({
    required int quality,
    required double currentEaseFactor,
  }) {
    // SM-2 公式
    // 新的 EF = 旧的 EF + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    double newEaseFactor = currentEaseFactor +
        (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));

    // 下限限制：不低于 1.3
    if (newEaseFactor < 1.3) {
      newEaseFactor = 1.3;
    }

    // 保留两位小数
    return double.parse(newEaseFactor.toStringAsFixed(2));
  }

  /// 计算新的间隔
  static int _calculateInterval({
    required int quality,
    required int currentInterval,
    required double easeFactor,
    required int reviewCount,
  }) {
    // 如果评分 < 3（没有记住），间隔重置为 1
    if (quality < 3) {
      return 1;
    }

    // 根据复习次数决定间隔的计算方式
    int newInterval;

    if (reviewCount == 0) {
      // 第一次学习
      newInterval = 1;
    } else if (reviewCount == 1) {
      // 第二次复习
      newInterval = 6;
    } else {
      // 第 3 次及以后：用公式计算
      newInterval = (currentInterval * easeFactor).round();
    }

    // 上限限制：不超过 365 天
    if (newInterval > 365) {
      newInterval = 365;
    }

    // 下限限制：至少 1 天
    if (newInterval < 1) {
      newInterval = 1;
    }

    return newInterval;
  }
}