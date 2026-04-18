import 'package:cached_network_image/cached_network_image.dart';
import 'package:diohub/common/misc/shimmer_bone.dart';
import 'package:diohub/common/misc/shimmer_scope.dart';
import 'package:diohub_models/models/entity_ref.dart';
import 'package:diohub_models/models/navigable.dart';
import 'package:diohub/routes/navigable_actions.dart';
import 'package:diohub/style/surface_ext.dart';
import 'package:diohub/style/surface_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

class ProfileTile extends ConsumerWidget {
  const ProfileTile.avatar({
    required this.avatarUrl,
    this.userLogin,
    this.padding = const EdgeInsets.all(8),
    this.size = 25,
    super.key,
    this.wrapperBuilder,
  })  : _type = _UserCardType.photo,
        fullName = null,
        disableTap = false,
        textStyle = null;

  const ProfileTile.login({
    required this.avatarUrl,
    required this.userLogin,
    this.padding = const EdgeInsets.all(8),
    this.size = 25,
    this.disableTap = false,
    this.textStyle,
    super.key,
    this.wrapperBuilder,
  })  : _type = _UserCardType.login,
        fullName = null;

  const ProfileTile.extended({
    required this.avatarUrl,
    required this.userLogin,
    required this.fullName,
    this.padding = const EdgeInsets.all(8),
    this.size = 25,
    this.disableTap = false,
    this.textStyle,
    super.key,
    this.wrapperBuilder,
  }) : _type = _UserCardType.extended;
  final String? avatarUrl;
  final double size;
  final String? userLogin;
  final String? fullName;
  final TextStyle? textStyle;
  final EdgeInsets padding;
  final bool disableTap;
  final _UserCardType _type;
  final Widget Function(Widget child)? wrapperBuilder;

  @override
  Widget build(final BuildContext context, final WidgetRef ref) {
    final Padding content = Padding(
      padding: padding,
      child: wrapperBuilder?.call(
            _buildContent(context),
          ) ??
          _buildContent(context),
    );

    final bool tapEnabled = userLogin != null && !disableTap;
    if (!tapEnabled) return content;

    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: () => UserRef(login: userLogin!).navigate(context, ref),
        borderRadius: context.radius(RadiusSize.small),
        child: content,
      ),
    );
  }

  Widget _buildContent(final BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: avatarUrl ?? 'N/A',
              width: size,
              height: size,
              memCacheWidth: (size * MediaQuery.of(context).devicePixelRatio)
                  .round()
                  .clamp(1, 512),
              memCacheHeight: (size * MediaQuery.of(context).devicePixelRatio)
                  .round()
                  .clamp(1, 512),
              fit: BoxFit.cover,
              placeholder: (final BuildContext context, final String string) =>
                  ShimmerScope(
                child: ShimmerBone.avatar(size: size),
              ),
              errorWidget: (final BuildContext context, final _, final __) =>
                  Icon(
                MdiIcons.ghost,
                size: size,
              ),
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (fullName != null)
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        fullName!,
                        style: (textStyle ??
                                const TextStyle(
                                    //   context,
                                    // ).currentSetting.baseElements,
                                    //  15,
                                    ))
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                if (_type != _UserCardType.photo)
                  Flexible(
                    child: Padding(
                      padding: EdgeInsets.only(left: size / 3),
                      child: Text(
                        userLogin ?? 'N/A',
                        style: textStyle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      );
}

enum _UserCardType { photo, login, extended }
