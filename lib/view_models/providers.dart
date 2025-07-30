import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'paintings_viewmodel.dart';

// Este es tu provider global de Riverpod para acceder a PaintingsViewModel
final paintingsViewModelProvider = ChangeNotifierProvider<PaintingsViewModel>((
  ref,
) {
  return PaintingsViewModel();
});
