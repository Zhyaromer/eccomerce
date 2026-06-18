import 'package:flutter/material.dart';
import 'package:e_commerce_flutter/src/model/product_category.dart';

class ListItemSelector extends StatefulWidget {
  const ListItemSelector({
    super.key,
    required this.categories,
    required this.onItemPressed,
  });

  final List<ProductCategory> categories;
  final Function(int) onItemPressed;

  @override
  State<ListItemSelector> createState() => _ListItemSelectorState();
}

class _ListItemSelectorState extends State<ListItemSelector> {
  Widget item(ProductCategory item, int index) {
    return Tooltip(
      message: item.name,
      child: AnimatedContainer(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        duration: const Duration(milliseconds: 500),
        height: 44,
        decoration: BoxDecoration(
          color: item.isSelected == false
              ? const Color(0xFFE5E6E8)
              : const Color(0xFFf16b26),
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextButton(
          onPressed: () {
            widget.onItemPressed(index);
            for (var element in widget.categories) {
              element.isSelected = false;
            }

            item.isSelected = true;
            setState(() {});
          },
          child: Text(
            item.name,
            selectionColor: item.isSelected == false
                ? const Color(0xFFA6A3A0)
                : Colors.white,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.categories.length,
        itemBuilder: (_, index) => item(widget.categories[index], index),
      ),
    );
  }
}
