// lib/screens/user/carrito/carrito_loading_state.dart

import 'package:flutter/cupertino.dart';
import '../../../theme/jp_theme.dart';

class CarritoLoadingState extends StatelessWidget {
  const CarritoLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CupertinoActivityIndicator(
        radius: 14,
        color: JPCupertinoColors.systemGrey(context),
      ),
    );
  }
}
