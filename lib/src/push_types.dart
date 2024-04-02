enum PushType { APNS, XiaoMi, ViVo, Oppo, FCM, Huawei }

extension StringPushType on PushType {
  String? coverToString() {
    if (this == PushType.APNS) {
      return "APNS";
    }
    if (this == PushType.XiaoMi) {
      return "XiaoMi";
    }
    if (this == PushType.ViVo) {
      return "ViVo";
    }

    if (this == PushType.Oppo) {
      return "Oppo";
    }
    if (this == PushType.FCM) {
      return "FCM";
    }
    if (this == PushType.Huawei) {
      return "Huawei";
    }

    return null;
  }
}

PushType? coverStringToPushType(String? pushTypeString) {
  if (pushTypeString == "APNS") {
    return PushType.APNS;
  }
  if ("XiaoMi" == pushTypeString) {
    return PushType.XiaoMi;
  }
  if ("ViVo" == pushTypeString) {
    return PushType.ViVo;
  }

  if ("Oppo" == pushTypeString) {
    return PushType.Oppo;
  }
  if ("FCM" == pushTypeString) {
    return PushType.FCM;
  }
  if ("Huawei" == pushTypeString) {
    return PushType.Huawei;
  }

  return null;
}
