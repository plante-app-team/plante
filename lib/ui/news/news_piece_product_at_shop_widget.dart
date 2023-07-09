import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:plante/base/date_time_extensions.dart';
import 'package:plante/l10n/strings.dart';
import 'package:plante/l10n/strings_time_ago.dart';
import 'package:plante/model/product.dart';
import 'package:plante/outside/news/news_cluster.dart';
import 'package:plante/ui/base/components/licence_label.dart';
import 'package:plante/ui/base/text_styles.dart';
import 'package:plante/ui/product/product_header_widget.dart';
import 'package:plante/ui/product/product_page_wrapper.dart';
import 'package:plante/ui/profile/components/avatar_widget.dart';

class NewsPieceProductAtShopWidget extends StatelessWidget {
  final Product product;
  final NewsCluster newsCluster;
  final Uri? authorAvatar;
  final Future<Map<String, String>> authHeaders;
  final VoidCallback onLocationTap;
  const NewsPieceProductAtShopWidget(this.product, this.newsCluster,
      this.authorAvatar, this.authHeaders, this.onLocationTap,
      {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.only(
                  left: 16, right: 12, top: 12, bottom: 12),
              child: Row(children: [
                if (authorAvatar != null)
                  SizedBox(
                      width: 40,
                      height: 40,
                      child: AvatarWidget(
                          uri: authorAvatar, authHeaders: authHeaders)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(newsCluster.authorName, style: TextStyles.headline4),
                  Text(
                      context.strings
                          .timeAgoFromDuration(durationOfNewsExistence()),
                      style: TextStyles.hint),
                ]),
              ])),
          ProductHeaderWidget(
            product: product,
            imageType: ProductImageType.FRONT,
            height: 200,
            borderRadius: 0,
            overlay: const _ProductLabelWidget(),
            includeSubtitle: false,
            onTap: () {
              ProductPageWrapper.show(context, product);
            },
          ),
          SizedBox(
              height: 54,
              child: Row(children: [
                const Expanded(child: SizedBox.shrink()),
                Expanded(
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _LocationButton(
                                key: const Key(
                                    'news_piece_product_location_button'),
                                onTap: onLocationTap)))),
              ]))
        ]));
  }

  Duration durationOfNewsExistence() {
    return DateTime.now().toUtc().difference(
        dateTimeFromSecondsSinceEpoch(newsCluster.creationTimeSecs));
  }
}

class _ProductLabelWidget extends StatelessWidget {
  const _ProductLabelWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
        child: Align(
            alignment: Alignment.topRight,
            child: LicenceLabel(
              label:
                  context.strings.news_feed_page_label_for_new_product_at_shop,
              darkBox: true,
            )));
  }
}

class _LocationButton extends StatelessWidget {
  final GestureTapCallback onTap;
  const _LocationButton({Key? key, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 34,
        height: 34,
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onTap,
                child: Center(
                    child: Wrap(children: [
                  SvgPicture.asset('assets/news_piece_shop_location.svg')
                ])))));
  }
}
