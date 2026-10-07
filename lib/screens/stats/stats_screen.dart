import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bytestreak/domain/stats.dart';
import 'package:bytestreak/state/providers.dart';
import 'package:bytestreak/theme/app_palette.dart';
import 'package:bytestreak/widgets/common.dart';

final _statsProvider = Provider<PlayerStats>((ref) {
  return PlayerStats.from(ref.watch(currentPlayerProvider), ref.watch(coursePathProvider), ref.watch(clockProvider)());
});

/// 1.10 Stats dashboard.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final s = ref.watch(_statsProvider);
    final change = s.accuracyChange;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: StatTile(label: 'Skill level', value: 'Level ${s.level}', caption: s.skill, color: p.xp)),
                const SizedBox(width: 14),
                Expanded(
                  child: StatTile(
                    label: 'Current streak',
                    value: '${s.streak} day${s.streak == 1 ? '' : 's'}',
                    caption: 'Personal best ${s.longestStreak}',
                    color: p.streak,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StatTile(
                    label: 'Questions solved',
                    value: formatNumber(s.solved),
                    caption: '+${s.solvedThisWeek} this week',
                    color: p.success,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: StatTile(
                    label: 'Overall accuracy',
                    value: formatPercent(s.accuracy),
                    caption: change == null
                        ? 'Keep going to see a trend'
                        : '${change >= 0 ? '+' : ''}${(change * 100).round()}% vs last month',
                    color: p.quiz,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 3, child: _MasteryCard(stats: s)),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _StrengthsColumn(stats: s)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // No IntrinsicHeight here: charts can't report their own height.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _HeatmapCard(stats: s)),
              const SizedBox(width: 16),
              Expanded(flex: 2, child: _TrendCard(stats: s)),
            ],
          ),
        ],
      ),
    );
  }
}

Color masteryColor(double? accuracy, AppPalette p) {
  if (accuracy == null) return p.faint;
  if (accuracy >= 0.7) return p.success;
  if (accuracy >= 0.4) return p.streak;
  return p.heart;
}

class _MasteryCard extends StatelessWidget {
  const _MasteryCard({required this.stats});
  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      title: 'Topic mastery',
      child: Column(
        children: [
          for (final t in stats.topics) ...[
            Row(
              children: [
                SizedBox(width: 160, child: Text(t.chapter.title, style: context.text.bodyMedium)),
                Expanded(
                  child: ProgressBar(value: t.accuracy ?? 0, color: masteryColor(t.accuracy, p), height: 10),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 70,
                  child: Text(
                    t.accuracy == null ? 'Not started' : formatPercent(t.accuracy),
                    textAlign: TextAlign.right,
                    style: context.text.labelMedium?.copyWith(color: t.accuracy == null ? p.faint : p.muted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _StrengthsColumn extends StatelessWidget {
  const _StrengthsColumn({required this.stats});
  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final best = stats.strongest;
    final worst = stats.weakest;
    if (best == null) {
      return AppCard(
        child: Center(
          child: Text(
            'Answer a few questions and your strongest and weakest topics show up here.',
            style: context.text.bodyMedium?.copyWith(color: p.muted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: AppCard(
            color: p.successSoft,
            borderColor: p.successSoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Strongest topic', style: context.text.labelMedium?.copyWith(color: p.success)),
                const SizedBox(height: 4),
                Text('${best.chapter.title} — ${formatPercent(best.accuracy)}', style: context.text.titleLarge?.copyWith(color: p.success)),
                const SizedBox(height: 4),
                Text('${best.correct} of ${best.attempts} answers correct.', style: context.text.bodySmall?.copyWith(color: p.success)),
              ],
            ),
          ),
        ),
        if (worst != null) ...[
          const SizedBox(height: 12),
          Expanded(
            child: AppCard(
              color: p.heartSoft,
              borderColor: p.heartSoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Needs work', style: context.text.labelMedium?.copyWith(color: p.heart)),
                  const SizedBox(height: 4),
                  Text('${worst.chapter.title} — ${formatPercent(worst.accuracy)}', style: context.text.titleLarge?.copyWith(color: p.heart)),
                  const SizedBox(height: 4),
                  Text(
                    '${worst.correct} of ${worst.attempts} correct. Revisit the chapter.',
                    style: context.text.bodySmall?.copyWith(color: p.heart),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () => context.go('/home?chapter=${worst.chapter.id}'),
                    child: Text('Practise ${worst.chapter.title}'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _HeatmapCard extends StatelessWidget {
  const _HeatmapCard({required this.stats});
  final PlayerStats stats;

  Color _shade(int n, AppPalette p) {
    if (n < 0) return Colors.transparent;
    if (n == 0) return p.sunken;
    final t = (n / 6).clamp(0.2, 1.0);
    return Color.lerp(p.successSoft, p.success, t)!;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      title: 'Practice consistency',
      action: Text('Last ${PlayerStats.heatmapWeeks} weeks', style: context.text.labelMedium?.copyWith(color: p.xp)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final week in stats.heatmap)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Column(
                    children: [
                      for (final n in week)
                        Tooltip(
                          message: n < 0 ? '' : '$n answer${n == 1 ? '' : 's'}',
                          child: Container(
                            width: 15,
                            height: 15,
                            margin: const EdgeInsets.only(bottom: 4),
                            decoration: BoxDecoration(color: _shade(n, p), borderRadius: BorderRadius.circular(3)),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 43),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text('Less', style: context.text.bodySmall?.copyWith(color: p.faint)),
              const SizedBox(width: 6),
              for (final n in [0, 1, 3, 5, 7])
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(right: 3),
                  decoration: BoxDecoration(color: _shade(n, p), borderRadius: BorderRadius.circular(3)),
                ),
              const SizedBox(width: 3),
              Text('More', style: context.text.bodySmall?.copyWith(color: p.faint)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.stats});
  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final spots = [
      for (final (i, v) in stats.weeklyAccuracy.indexed)
        if (v != null) FlSpot(i.toDouble(), (v * 100).roundToDouble()),
    ];
    final weeks = stats.weeklyAccuracy.length;

    return AppCard(
      title: 'Accuracy over time',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 170,
            child: spots.length < 2
                ? Center(
                    child: Text(
                      'Practise across a couple of weeks to see a trend.',
                      style: context.text.bodySmall?.copyWith(color: p.faint),
                      textAlign: TextAlign.center,
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (weeks - 1).toDouble(),
                      minY: 0,
                      maxY: 100,
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (_) => FlLine(color: p.lineSoft, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 2,
                            reservedSize: 22,
                            getTitlesWidget: (v, meta) => SideTitleWidget(
                              meta: meta,
                              child: Text(
                                v.toInt() == weeks - 1 ? 'now' : '-${weeks - 1 - v.toInt()}w',
                                style: context.text.labelSmall?.copyWith(color: p.faint),
                              ),
                            ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 25,
                            reservedSize: 36,
                            getTitlesWidget: (v, meta) => SideTitleWidget(
                              meta: meta,
                              child: Text('${v.toInt()}%', style: context.text.labelSmall?.copyWith(color: p.faint)),
                            ),
                          ),
                        ),
                      ),
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipColor: (_) => p.ink,
                          getTooltipItems: (spots) => [
                            for (final s in spots)
                              LineTooltipItem('${s.y.toInt()}%', TextStyle(color: p.background, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          preventCurveOverShooting: true,
                          color: p.xp,
                          barWidth: 3,
                          dotData: const FlDotData(),
                          belowBarData: BarAreaData(show: true, color: p.xp.withValues(alpha: 0.1)),
                        ),
                      ],
                    ),
                  ),
          ),
          const SizedBox(height: 8),
          Text('Weekly accuracy, last ${PlayerStats.trendWeeks} weeks', style: context.text.bodySmall?.copyWith(color: p.faint)),
        ],
      ),
    );
  }
}
