import 'package:flutter/material.dart';
import 'package:e_commerce_flutter/core/app_color.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class CarouselSlider extends StatefulWidget {
  const CarouselSlider({
    super.key,
    required this.items,
  });

  final List<String> items;

  @override
  State<CarouselSlider> createState() => _CarouselSliderState();
}

class _CarouselSliderState extends State<CarouselSlider> {
  int newIndex = 0;

  Widget _image(String image) {
    if (image.isEmpty) {
      return const Icon(Icons.image_not_supported_outlined, size: 70);
    }

    final isNetworkImage =
        image.startsWith('http://') || image.startsWith('https://');

    return isNetworkImage
        ? Image.network(
            image,
            scale: 3,
            errorBuilder: (_, __, ___) {
              return const Icon(Icons.image_not_supported_outlined, size: 70);
            },
          )
        : Image.asset(
            image,
            scale: 3,
            errorBuilder: (_, __, ___) {
              return const Icon(Icons.image_not_supported_outlined, size: 70);
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;
    final items = widget.items.isEmpty ? [''] : widget.items;

    return Column(
      children: [
        SizedBox(
          height: height * 0.32,
          child: PageView.builder(
            itemCount: items.length,
            onPageChanged: (int currentIndex) {
              newIndex = currentIndex;
              setState(() {});
            },
            itemBuilder: (_, index) {
              return FittedBox(
                fit: BoxFit.none,
                child: _image(items[index]),
              );
            },
          ),
        ),
        AnimatedSmoothIndicator(
          effect: const WormEffect(
            dotColor: Colors.white,
            activeDotColor: AppColor.darkOrange,
          ),
          count: items.length,
          activeIndex: newIndex,
        )
      ],
    );
  }
}
