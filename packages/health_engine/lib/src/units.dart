/// Đổi đơn vị trên nhãn bổ sung sang đơn vị chuẩn của gói dữ liệu.
library;

import 'reference_pack.dart';

enum VitaminEForm { natural, synthetic }

class UnitConverter {
  final Map<String, double> _c;
  UnitConverter(ReferencePack pack) : _c = pack.unitConversions;

  /// Vitamin D: IU → µg.
  double vitDIuToUg(double iu) => iu * _c['vitD_IU_to_ug']!;

  /// Vitamin A dạng retinol (có sẵn): IU → µg RAE.
  double vitARetinolIuToUgRae(double iu) => iu * _c['vitA_retinol_IU_to_ug_RAE']!;

  /// Beta-caroten trong thực phẩm bổ sung: IU → µg RAE.
  double vitABetaCaroteneSupplementIuToUgRae(double iu) =>
      iu * _c['vitA_supplemental_betacarotene_IU_to_ug_RAE']!;

  /// Vitamin E: IU → mg alpha-tocopherol, theo dạng tự nhiên (d-) hay tổng hợp (dl-).
  double vitEIuToMg(double iu, VitaminEForm form) => iu *
      (form == VitaminEForm.natural
          ? _c['vitE_natural_IU_to_mg']!
          : _c['vitE_synthetic_IU_to_mg']!);

  /// Axit folic (µg) → µg DFE.
  double folicAcidToDfe(double ug) => ug * _c['folicAcid_ug_to_ug_DFE']!;
}
