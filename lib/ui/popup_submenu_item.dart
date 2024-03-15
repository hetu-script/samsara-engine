import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';

/// An item with sub menu for using in popup menus
///
/// [title] is the text which will be displayed in the pop up
/// [values] is the list of items to populate the sub menu
/// [onSelected] is the callback to be fired if specific item is pressed
///
/// Selecting items from the submenu will automatically close the parent menu
/// Closing the sub menu by clicking outside of it, will automatically close the parent menu
class PopupSubMenuItem<T> extends PopupMenuEntry<T> {
  const PopupSubMenuItem({
    super.key,
    required this.title,
    required this.items,
    this.height = 24.0,
    this.width = 120.0,
    this.offset = Offset.zero,
    this.onSelected,
    this.textStyle,
  });

  final String title;
  @override
  final double height;
  final double width;
  final Offset offset;
  final Map<String, T> items;
  final Function(T)? onSelected;
  final TextStyle? textStyle;

  @override
  bool represents(T? value) =>
      false; //Our submenu does not represent any specific value for the parent menu

  @override
  State createState() => _PopupSubMenuState<T>();
}

/// The [State] for [PopupSubMenuItem] subclasses.
class _PopupSubMenuState<T> extends State<PopupSubMenuItem<T>> {
  @override
  Widget build(BuildContext context) {
    TextStyle style = widget.textStyle ??
        (PopupMenuTheme.of(context).textStyle ??
                Theme.of(context).textTheme.titleMedium!)
            .merge(const TextStyle(fontSize: 14.0));

    return PopupMenuButton<T>(
      tooltip: '',
      onCanceled: () {
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      },
      onSelected: (T value) {
        if (Navigator.canPop(context)) {
          Navigator.pop<T>(context, value);
        }
        widget.onSelected?.call(value);
      },
      offset: widget.offset,
      itemBuilder: (BuildContext context) {
        final items = <PopupMenuEntry<T>>[];
        for (final key in widget.items.keys) {
          final value = widget.items[key];
          items.add(PopupMenuItem<T>(
            height: widget.height,
            value: value,
            child: Container(
              alignment: Alignment.centerLeft,
              width: widget.width,
              child: Text(key, style: style),
            ),
          ));
        }
        return items;
      },
      child: Container(
        padding: const EdgeInsets.only(left: 11.0),
        alignment: Alignment.centerLeft,
        width: widget.width,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.max,
          children: [
            Expanded(
              child: Text(widget.title, style: style),
            ),
            Icon(
              Icons.arrow_right,
              size: widget.height,
              color: Theme.of(context).iconTheme.color,
            ),
          ],
        ),
      ),
    );
  }
}
