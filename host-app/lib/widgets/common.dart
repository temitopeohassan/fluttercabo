import 'package:flutter/material.dart';

import '../theme.dart';

void go(BuildContext context, String route) =>
    Navigator.of(context).pushNamed(route);

void replace(BuildContext context, String route) =>
    Navigator.of(context).pushReplacementNamed(route);

void back(BuildContext context) => Navigator.of(context).maybePop();

enum CaboButtonStyle { primary, secondary, green, danger, light }

/// Large, one-hand friendly button used throughout the app.
class CaboButton extends StatelessWidget {
  const CaboButton(
    this.label, {
    super.key,
    this.onPressed,
    this.icon,
    this.style = CaboButtonStyle.primary,
    this.height = 56,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CaboButtonStyle style;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (style) {
      CaboButtonStyle.primary => (CaboColors.yellow, CaboColors.onYellow, null),
      CaboButtonStyle.secondary => (
        Colors.transparent,
        CaboColors.text,
        CaboColors.muted,
      ),
      CaboButtonStyle.green => (CaboColors.green, CaboColors.text, null),
      CaboButtonStyle.danger => (CaboColors.red, Colors.white, null),
      CaboButtonStyle.light => (Colors.white, CaboColors.onYellow, null),
    };
    final disabled = onPressed == null;
    final child = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 22, color: fg),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: height >= 56 ? 17 : 15,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ],
    );
    return Opacity(
      opacity: disabled ? 0.45 : 1,
      child: Material(
        color: bg,
        shape: StadiumBorder(
          side: border == null
              ? BorderSide.none
              : BorderSide(color: border, width: 1.5),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: Container(
            height: height,
            padding: const EdgeInsets.symmetric(horizontal: 22),
            alignment: expand ? Alignment.center : null,
            child: child,
          ),
        ),
      ),
    );
  }
}

PreferredSizeWidget caboAppBar(
  BuildContext context,
  String title, {
  List<Widget>? actions,
  bool showBack = true,
}) {
  final canPop = Navigator.of(context).canPop();
  return AppBar(
    automaticallyImplyLeading: false,
    leading: showBack && canPop
        ? IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => back(context),
          )
        : null,
    title: Text(title),
    actions: actions,
  );
}

/// Standard screen: app bar, scrolling content and an optional bottom bar.
class CaboScaffold extends StatelessWidget {
  const CaboScaffold({
    super.key,
    required this.title,
    required this.children,
    this.bottom,
    this.actions,
    this.bottomNav,
    this.padding = const EdgeInsets.fromLTRB(20, 8, 20, 24),
    this.showBack = true,
  });

  final String title;
  final List<Widget> children;
  final Widget? bottom;
  final List<Widget>? actions;
  final Widget? bottomNav;
  final EdgeInsets padding;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: caboAppBar(context, title, actions: actions, showBack: showBack),
      body: ListView(padding: padding, children: children),
      bottomNavigationBar:
          bottomNav ??
          (bottom == null ? null : BottomActionBar(child: bottom!)),
    );
  }
}

class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: CaboColors.deepGreen,
        border: Border(top: BorderSide(color: CaboColors.surfaceHigh)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: child,
        ),
      ),
    );
  }
}

class CaboCard extends StatelessWidget {
  const CaboCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = CaboColors.surface,
    this.borderColor,
    this.onTap,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: borderColor == null
            ? BorderSide.none
            : BorderSide(color: borderColor!, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.onAction});
  final String text;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(text, style: CaboText.h3)),
          if (action != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                action!,
                style: CaboText.label.copyWith(color: CaboColors.yellow),
              ),
            ),
        ],
      ),
    );
  }
}

class Pill extends StatelessWidget {
  const Pill(
    this.text, {
    super.key,
    this.color = CaboColors.yellow,
    this.icon,
    this.solid = false,
  });
  final String text;
  final Color color;
  final IconData? icon;
  final bool solid;

  @override
  Widget build(BuildContext context) {
    final fg = solid ? CaboColors.onYellow : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: solid ? color : color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class IconBadge extends StatelessWidget {
  const IconBadge(
    this.icon, {
    super.key,
    this.color = CaboColors.yellow,
    this.size = 44,
  });
  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Icon(icon, color: color, size: size * 0.52),
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(
    this.initials, {
    super.key,
    this.size = 48,
    this.color = CaboColors.yellow,
  });
  final String initials;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white24, width: 2),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          color: CaboColors.onYellow,
        ),
      ),
    );
  }
}

class MenuTile extends StatelessWidget {
  const MenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.color = CaboColors.yellow,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            IconBadge(icon, color: color, size: 40),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null) Text(subtitle!, style: CaboText.muted),
                ],
              ),
            ),
            trailing ??
                (onTap != null
                    ? const Icon(Icons.chevron_right, color: CaboColors.muted)
                    : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  const InfoRow(
    this.label,
    this.value, {
    super.key,
    this.valueColor,
    this.bold = false,
  });
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(label, style: CaboText.muted.copyWith(fontSize: 14)),
          ),
          const SizedBox(width: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 200),
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: CaboText.body.copyWith(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                fontSize: bold ? 16 : 14,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile(
    this.label,
    this.value, {
    super.key,
    this.icon,
    this.color = CaboColors.yellow,
    this.caption,
  });
  final String label;
  final String value;
  final IconData? icon;
  final Color color;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return CaboCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: CaboText.h2.copyWith(color: color)),
          ),
          const SizedBox(height: 2),
          Text(label, style: CaboText.muted.copyWith(fontSize: 12)),
          if (caption != null)
            Text(
              caption!,
              style: CaboText.muted.copyWith(
                fontSize: 11,
                color: CaboColors.faint,
              ),
            ),
        ],
      ),
    );
  }
}

class Bar extends StatelessWidget {
  const Bar(
    this.value, {
    super.key,
    this.color = CaboColors.yellow,
    this.height = 8,
  });
  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value,
        minHeight: height,
        color: color,
        backgroundColor: CaboColors.surfaceHigh,
      ),
    );
  }
}

class Stars extends StatelessWidget {
  const Stars(this.rating, {super.key, this.size = 18});
  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final icon = rating >= i + 1
            ? Icons.star_rounded
            : rating > i
            ? Icons.star_half_rounded
            : Icons.star_outline_rounded;
        return Icon(icon, size: size, color: CaboColors.yellow);
      }),
    );
  }
}

/// A tappable card that behaves like a radio or checkbox option.
class SelectTile extends StatelessWidget {
  const SelectTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.multi = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
  final Widget? trailing;
  final bool multi;

  @override
  Widget build(BuildContext context) {
    final mark = multi
        ? (selected
              ? Icons.check_box_rounded
              : Icons.check_box_outline_blank_rounded)
        : (selected ? Icons.radio_button_checked : Icons.radio_button_off);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: CaboCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderColor: selected ? CaboColors.yellow : CaboColors.surfaceHigh,
        child: Row(
          children: [
            if (icon != null) ...[
              IconBadge(icon!, size: 40),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (subtitle != null) Text(subtitle!, style: CaboText.muted),
                ],
              ),
            ),
            ?trailing,
            const SizedBox(width: 8),
            Icon(
              mark,
              color: selected ? CaboColors.yellow : CaboColors.muted,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

/// Single-choice list of [SelectTile]s that manages its own selection.
class SingleChoice extends StatefulWidget {
  const SingleChoice({
    super.key,
    required this.options,
    this.initial = 0,
    this.icons,
  });
  final List<(String, String?)> options;
  final List<IconData>? icons;
  final int initial;

  @override
  State<SingleChoice> createState() => _SingleChoiceState();
}

class _SingleChoiceState extends State<SingleChoice> {
  late int selected = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < widget.options.length; i++)
          SelectTile(
            title: widget.options[i].$1,
            subtitle: widget.options[i].$2,
            icon: widget.icons?[i],
            selected: selected == i,
            onTap: () => setState(() => selected = i),
          ),
      ],
    );
  }
}

class ToggleTile extends StatefulWidget {
  const ToggleTile(
    this.title, {
    super.key,
    this.subtitle,
    this.initial = true,
    this.icon,
  });
  final String title;
  final String? subtitle;
  final bool initial;
  final IconData? icon;

  @override
  State<ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<ToggleTile> {
  late bool value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (widget.icon != null) ...[
            IconBadge(widget.icon!, size: 40),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: CaboText.body.copyWith(fontWeight: FontWeight.w600),
                ),
                if (widget.subtitle != null)
                  Text(widget.subtitle!, style: CaboText.muted),
              ],
            ),
          ),
          Switch(value: value, onChanged: (v) => setState(() => value = v)),
        ],
      ),
    );
  }
}

/// Wrap of selectable chips (multi-select).
class ChipPicker extends StatefulWidget {
  const ChipPicker({
    super.key,
    required this.options,
    this.initial = const {},
    this.single = false,
  });
  final List<String> options;
  final Set<int> initial;
  final bool single;

  @override
  State<ChipPicker> createState() => _ChipPickerState();
}

class _ChipPickerState extends State<ChipPicker> {
  late Set<int> selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < widget.options.length; i++)
          GestureDetector(
            onTap: () => setState(() {
              if (widget.single) {
                selected = {i};
              } else if (!selected.remove(i)) {
                selected.add(i);
              }
            }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: selected.contains(i)
                    ? CaboColors.yellow
                    : CaboColors.surface,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: selected.contains(i)
                      ? CaboColors.yellow
                      : CaboColors.surfaceHigh,
                ),
              ),
              child: Text(
                widget.options[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: selected.contains(i)
                      ? CaboColors.onYellow
                      : CaboColors.text,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CaboField extends StatelessWidget {
  const CaboField(
    this.label, {
    super.key,
    this.value,
    this.hint,
    this.icon,
    this.suffix,
    this.maxLines = 1,
    this.keyboardType,
  });
  final String label;
  final String? value;
  final String? hint;
  final IconData? icon;
  final Widget? suffix;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: CaboText.label),
          const SizedBox(height: 6),
          TextFormField(
            initialValue: value,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: CaboText.body.copyWith(fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: icon == null
                  ? null
                  : Icon(icon, color: CaboColors.muted, size: 20),
              suffixIcon: suffix,
            ),
          ),
        ],
      ),
    );
  }
}

/// Onboarding step with progress, heading and a continue button.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.step,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.next,
    this.buttonLabel = 'Continue',
    this.totalSteps = 9,
  });

  final int step;
  final int totalSteps;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String next;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: caboAppBar(context, 'Step $step of $totalSteps'),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          Bar(step / totalSteps, height: 6),
          const SizedBox(height: 22),
          Text(title, style: CaboText.h1),
          const SizedBox(height: 6),
          Text(subtitle, style: CaboText.muted.copyWith(fontSize: 14)),
          const SizedBox(height: 22),
          ...children,
        ],
      ),
      bottomNavigationBar: BottomActionBar(
        child: CaboButton(buttonLabel, onPressed: () => go(context, next)),
      ),
    );
  }
}

/// Full-screen state used for errors, blockers and confirmations.
class StateScreen extends StatelessWidget {
  const StateScreen({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = CaboColors.yellow,
    this.primary,
    this.onPrimary,
    this.secondary,
    this.onSecondary,
    this.extra,
    this.top,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final String? primary;
  final VoidCallback? onPrimary;
  final String? secondary;
  final VoidCallback? onSecondary;
  final Widget? extra;
  final Widget? top;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: top ?? const SizedBox(height: 40),
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.12),
                        ),
                        child: Center(
                          child: Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withValues(alpha: 0.22),
                            ),
                            child: Icon(icon, size: 44, color: color),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        title,
                        style: CaboText.h1,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        style: CaboText.muted.copyWith(fontSize: 15),
                        textAlign: TextAlign.center,
                      ),
                      if (extra != null) ...[
                        const SizedBox(height: 24),
                        extra!,
                      ],
                    ],
                  ),
                ),
              ),
              if (primary != null)
                CaboButton(primary!, onPressed: onPrimary ?? () {}),
              if (secondary != null) ...[
                const SizedBox(height: 12),
                CaboButton(
                  secondary!,
                  style: CaboButtonStyle.secondary,
                  onPressed: onSecondary ?? () => back(context),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Chat bubble for rider and support chats.
class ChatBubble extends StatelessWidget {
  const ChatBubble(
    this.text, {
    super.key,
    required this.mine,
    this.time,
    this.note,
  });
  final String text;
  final bool mine;
  final String? time;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 290),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: mine ? CaboColors.yellow : CaboColors.surfaceHigh,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(mine ? 18 : 4),
              bottomRight: Radius.circular(mine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: CaboText.body.copyWith(
                  color: mine ? CaboColors.onYellow : CaboColors.text,
                ),
              ),
              if (note != null || time != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    [?note, ?time].join(' • '),
                    style: TextStyle(
                      fontSize: 11,
                      color: mine
                          ? CaboColors.onYellow.withValues(alpha: 0.7)
                          : CaboColors.muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChatInput extends StatelessWidget {
  const ChatInput({super.key, this.hint = 'Type a message'});
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            style: CaboText.body,
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: CaboColors.yellow,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.send_rounded, color: CaboColors.onYellow),
        ),
      ],
    );
  }
}

/// Round icon button used for call / chat / SOS actions.
class RoundAction extends StatelessWidget {
  const RoundAction(
    this.icon, {
    super.key,
    this.label,
    this.onTap,
    this.color = CaboColors.surfaceHigh,
    this.iconColor = CaboColors.text,
    this.size = 52,
  });
  final IconData icon;
  final String? label;
  final VoidCallback? onTap;
  final Color color;
  final Color iconColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap ?? () {},
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, color: iconColor, size: size * 0.46),
            ),
          ),
        ),
        if (label != null) ...[
          const SizedBox(height: 6),
          Text(label!, style: CaboText.label),
        ],
      ],
    );
  }
}
