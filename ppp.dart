import 'dart:async';
import 'dart:io';
import 'package:photo_view/photo_view_gallery.dart' as SealPhotoGallery;
import 'package:chewie/chewie.dart';
import 'package:date_format/date_format.dart';
import 'package:event_bus/event_bus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_pickers/pickers.dart';
import 'package:flutter_pickers/style/default_style.dart';
import 'package:flutter_pickers/style/picker_style.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:fluwx/fluwx.dart' as fluwx;

// import 'package:rxdart/rxdart.dart';
import 'package:video_player/video_player.dart';
import 'package:youshangyun_app/application.dart';
import 'package:youshangyun_app/base/base_page.dart';
import 'package:youshangyun_app/base/event_bus_action.dart';
import 'package:youshangyun_app/base/event_const.dart';
import 'package:youshangyun_app/components/NetworkCus.dart';
import 'package:youshangyun_app/components/dialog/ConfirmDialog.dart';
import 'package:youshangyun_app/components/dialog/SingleImageDialog.dart';
import 'package:youshangyun_app/components/dialog/VideoPlayShow.dart';
import 'package:youshangyun_app/http/address.dart';
import 'package:youshangyun_app/http/http_utils.dart';
import 'package:youshangyun_app/http/response/DictModel.dart';
import 'package:youshangyun_app/http/service/common_service.dart';
import 'package:youshangyun_app/model/seal_photo_model.dart';
import 'package:youshangyun_app/page/common/gradient_button.dart';
import 'package:youshangyun_app/page/common/red_circle_checkbox.dart';
import 'package:youshangyun_app/page/common/top_bar.dart';
import 'package:youshangyun_app/page/common/video/video_controls_overlay.dart';
import 'package:youshangyun_app/page/seal/car_factory_sheet.dart';
import 'package:youshangyun_app/routes/route_name_const.dart';
import 'package:youshangyun_app/styles/colours.dart';
import 'package:youshangyun_app/styles/icon_const.dart';
import 'package:youshangyun_app/utils/android_method_call.dart';
import 'package:youshangyun_app/utils/screen_utils.dart';
import 'package:youshangyun_app/utils/shared_preference_util.dart';
import 'package:youshangyun_app/view_model/common_view_model.dart';
import 'package:youshangyun_app/view_model/seal_view_model.dart';

import '../../utils/logistics_utils.dart';
import '../../utils/toast.dart';
import '../../utils/unity.dart';

class SealPublishPage extends BasePage {
  @override
  BasePageState<BasePage> getPageState() {
    return SealPublishPageState();
  }
}

class SealPublishPageState extends BasePageState<SealPublishPage> {
  //付款方式
  int currentSelectedPayType = 0;
  String payType = "WxPay";

  //选择厂商
  String selectCarFactory = "";

  //选择出厂时间
  String selectCarTime = "";

  //选择
  String selectCarTimeSave = "";

  //支付监听
  StreamSubscription payListen;

  //视频控制器
  VideoPlayerController _controllerLocal;
  VideoPlayerController _controllerLocalOilCarVideo;

  bool isInitVideo = false;
  bool isInitOilVideo = false;

  //是否同时播放
  bool videoKeep = false;

  ChewieController _chewieCarLocalController;
  ChewieController _chewieOilLocalCarController;


  //模型
  CommonViewModel commonViewModel;
  SealViewModel sealViewModel;

  //手机号文本控制器
  TextEditingController ownerPhoneEditingController = TextEditingController();
  TextEditingController driverPhoneEditingController = TextEditingController();

  //车牌号文本控制器
  TextEditingController carNoEditingController = TextEditingController();

  //用户id
  String id = "";

  //是否是铅封人员
  bool isNormalUser = true;
  String tel = "";
  bool isModify = false;
  String sealPrice = "0";

  //是否为发布模式，发布模式使用数据字典数据
  bool isEdit = true;

  //铅封示例
  List<SealPhotoModel> sealPhotoList = [];
  String selectCarPhotoLocal = "";
  String selectGuanPhotoLocal = "";
  String selectOilCheckPhotoLocal = "";
  String selectpoundImgUrlPhotoLocal = "";
  String selectCarVideoLocal = "";
  String selectOilCheckVideoLocal = "";
  String selectUpPhotoLocal = "";
  String selectUpFullPhotoLocal = "";
  String selectDownPhotoLocal = "";
  String selectDownFullPhotoLocal = "";
  String selectFrontPhotoLocal = "";
  String selectFrontFullPhotoLocal = "";
  String selectLeftPhotoLocal = "";
  String selectLeftFullPhotoLocal = "";
  String selectRightPhotoLocal = "";
  String selectRightFullPhotoLocal = "";
  String selectNo6ImgUrlPhotoLocal = "";
  String selectNo7ImgUrlPhotoLocal = "";
  String selectNo8ImgUrlPhotoLocal = "";
  String selectNo6ImgFullUrlPhotoLocal = "";
  String selectNo7ImgFullUrlPhotoLocal = "";
  String selectNo8ImgFullUrlPhotoLocal = "";
  bool isNeedRefreshSealPhoto = true;

  int currentIndex = 1;

  @override
  void initState() {
    super.initState();
    //客服电话获取
    _getTel();
    commonViewModel = Provider.of<CommonViewModel>(context, listen: false);
    sealViewModel = Provider.of<SealViewModel>(context, listen: false);
    sealViewModel.sealModel = null;
    payListen = fluwx.weChatResponseEventHandler.listen((event) {
      //监听调起
      if (event.errCode == 0) {
        saveSeal();
      } else {
        ToastUtils.showToast(event.errStr ?? "微信支付失败");
        return;
      }
    });
  }

  Future _getTel() async {
    await HttpManager.get(ApiAddress.tel(), null, (code, data) async {
      if (data.data != null && data.data['code'] == 0) {
        List telList = data.data['data'];
        print(telList);
        Map telMap = telList[0];
        setState(() {
          tel = telMap["dictValue"];
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    Map map = ModalRoute.of(context).settings.arguments;
    if (map != null) {
      id = map["id"];
      isNormalUser = !map["isSealer"];
      if (id != null && id.isNotEmpty) {
        sealViewModel.getSealInfo(id);
      }
      isEdit = id == null || id.isEmpty;
    }
  }

  DateTime _lastPressTime;

  @override
  Widget generateContentWidget(BuildContext context) {
    return Consumer<SealViewModel>(builder: (ctx, model, _) {
      return WillPopScope(
        onWillPop: () {
          if (_lastPressTime == null ||
              DateTime.now().difference(_lastPressTime) >
                  Duration(seconds: 1)) {
            _lastPressTime = DateTime.now();
            Fluttertoast.showToast(msg: "在按一次退出");
            return Future.value(false);
          }
          return Future.value(true);
        },
        child: Scaffold(
          appBar: PreferredSize(
              preferredSize: Size.fromHeight(60.0),
              child: TopBar(
                  appBarText:
                      isNormalUser ? (isEdit ? "铅封发布" : "铅封服务") : "铅封信息",
                  isShowAction: isEdit ||
                      (isNormalUser && model.sealModel?.status == "0"),
                  isShowLeading: isEdit ? false : true,
                  actionList: <Widget>[
                    InkWell(
                      child: Container(
                        margin: EdgeInsets.only(right: 20),
                        alignment: Alignment.center,
                        child: Text(
                          (!isEdit && model.sealModel?.status == "0")
                              ? (isModify ? "完成" : "编辑")
                              : "服务记录",
                          style:
                              TextStyle(fontSize: 12, color: Colours.textBlue),
                        ),
                      ),
                      onTap: () {
                        if (!isEdit && model.sealModel?.status == "0") {
                          if (isModify) {
                            // 更新数据
                            bool result = updateSeal(false);
                            if (result) {
                              setState(() {
                                isModify = !isModify;
                              });
                            }
                          } else {
                            setState(() {
                              isModify = !isModify;
                            });
                          }
                        } else {
                          // 跳转到服务列表
                          pushNamedPage(sealListRoute)
                              .whenComplete(() => pop());
                        }
                      },
                    )
                  ],
                  fn: () {
                    pop();
                  })),
          body: Container(
            height: double.infinity,
            color: Colours.bg,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfo(),
                  _buildPhoneInfo(),
                  Visibility(
                    child: _buildPayInfo(),
                    visible: isEdit,
                  ),
                  Visibility(
                    child: _buildServicePhone(),
                    visible: !isEdit,
                  ),
                  Visibility(
                    visible: isEdit,
                    child: Container(
                        margin: EdgeInsets.only(top: 70, left: 28, right: 28),
                        child: GradientButton(
                            "确认支付￥$sealPrice", 0xFFFF489D, 0xFFFF4600, () {
                          pay();
                        })),
                  ),
                  Visibility(
                    visible: !(isNormalUser &&
                        sealViewModel.sealModel?.status == "0"),
                    child: Container(
                      margin: EdgeInsets.only(top: 20, left: 10),
                      child: Text(
                        isEdit ? "铅封效果(示例)" : "铅封效果",
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFDC1F3E),
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  _buildCarPhoto(0),
                  _buildCarPhoto(1),
                  _buildCarPhoto(2),
                  _buildCarPhoto(3),
                  // _buildCarVideo(),
                  _buildOilCarVideo(),
                  _buildSealPhoto(),
                  SizedBox(
                    height: 12,
                  ),
                  Visibility(
                    visible:
                        !isNormalUser && sealViewModel.sealModel?.status != "2",
                    child: GradientButton(
                        sealViewModel.sealModel?.status == "0" ? "接单" : "提交",
                        0xFFFF489D,
                        0xFFFF4600, () {
                      updateSeal(true);
                    }),
                  ),
                  Visibility(
                    visible: isNormalUser &&
                        sealViewModel.sealModel?.status == "0" &&
                        !isEdit,
                    child: GradientButton("取消服务", 0xFFFF489D, 0xFFFF4600, () {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return ConfirmDialog(
                              title: '您确认取消该服务吗？',
                              rightF: () {
                                sealViewModel.cancelSeal(
                                    "${sealViewModel.sealModel.id}", (value) {
                                  if (value) {
                                    Fluttertoast.showToast(
                                        msg: "取消成功,请联系客服人员进行退款");
                                    fire(RefreshSealListEvent());
                                    pop();
                                  } else {
                                    Fluttertoast.showToast(msg: "取消失败");
                                  }
                                });
                              },
                            );
                          });
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  _buildBasicInfo() {
    String carNo = "";
    if (!isEdit) {
      selectCarFactory = sealViewModel.sealModel?.truckPoint ?? "";
      selectCarTime = sealViewModel.sealModel?.planDeliveryDate ?? "";
      carNo = sealViewModel.sealModel?.carNo ?? "";
    }
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          //此处修改
          InkWell(
            onTap: () {
              //如果是编辑状态 编辑状态在前锋发布中 还有前锋服务中
              //铅封发布中的编辑状态返回
              if (!isEdit) {
                return;
              }
              showCarFactorySelect();
            },
            //装车地点可以只能在铅封发布修改
            child: _buildItem(
                "装车地点", selectCarFactory.isEmpty ? "请选择装车地点" : selectCarFactory,
                isRequired: true,
                rightTextColor:
                    isEdit ? Colours.textBlue : Colours.textGrayA3A0),
          ),
          Divider(height: 1, color: Colours.grayA3A0),
          InkWell(
            onTap: () {
              if (!isEdit && !isModify) {
                return;
              }
              showTimeSelect();
            },
            child: _buildItem(
              "预计出厂时间",
              selectCarTime.isEmpty ? "请选择出厂时间" : selectCarTime,
              isRequired: true,
            ),
          ),
          Divider(height: 1, color: Colours.grayA3A0),
          _buildItem("车牌号", carNo.isEmpty ? "请输入车牌号" : carNo,
              rightEdit: isEdit || isModify,
              isRequired: true,
              controller: carNoEditingController),
        ],
      ),
    );
  }

  _buildPhoneInfo() {
    String ownerPhone = "";
    String driverPhone = "";
    if (!isEdit) {
      ownerPhone = sealViewModel.sealModel?.shipperMobile ?? "";
      driverPhone = sealViewModel.sealModel?.driverMobile ?? "";
    }
    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Visibility(
            visible: isNormalUser,
            child: _buildItem(
                "货主电话", ownerPhone.isEmpty ? "请输入联系电话" : ownerPhone,
                isRequired: true,
                rightEdit: isEdit || isModify,
                controller: ownerPhoneEditingController),
          ),
          Visibility(
              visible: isNormalUser,
              child: Divider(height: 1, color: Colours.grayA3A0)),
          InkWell(
            onTap: () {
              if (driverPhone.isNotEmpty) {
                LogisticsUtils.showCallPhoneDialog(context, driverPhone);
              }
            },
            child: _buildItem(
                "司机电话", driverPhone.isEmpty ? "请输入联系电话" : driverPhone,
                isRequired: true,
                rightEdit: isEdit || isModify,
                rightTextColor: Colours.textBlue,
                controller: driverPhoneEditingController),
          ),
        ],
      ),
    );
  }

  _buildServicePhone() {
    if (!isNormalUser) {
      return Container();
    }
    // String servicePhone = "";
    // if (!isEdit) {
    //   servicePhone = sealViewModel.sealModel?.shipperMobile ?? "";
    // }
    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          _buildItem("服务电话", tel,
              rightTextColor: Colours.textBlue,
              controller: ownerPhoneEditingController),
        ],
      ),
    );
  }

  _buildPayInfo() {
    return Container(
      margin: EdgeInsets.only(top: 10),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 45,
                child: Row(
                  children: [
                    Icon(
                      payWeChat,
                      color: Color(0xFF1afa29),
                    ),
                    SizedBox(width: 22),
                    Text(
                      "微信支付",
                      style:
                          TextStyle(fontSize: 14, color: Colours.textBlack32),
                    )
                  ],
                ),
              ),
              RedCircleCheckBox(
                value: currentSelectedPayType == 0,
                onChanged: (value) {
                  payType = "WxPay";
                  setState(() {
                    if (value) {
                      currentSelectedPayType = 0;
                    }
                  });
                },
              )
            ],
          ),
          /*Divider(height: 1, color: Colours.grayA3A0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 45,
                child: Row(
                  children: [
                    Icon(
                      payAli,
                      color: Color(0xFF1296db),
                    ),
                    SizedBox(width: 22),
                    Text(
                      "支付宝支付",
                      style:
                          TextStyle(fontSize: 14, color: Colours.textBlack32),
                    )
                  ],
                ),
              ),
              RedCircleCheckBox(
                value: currentSelectedPayType == 1,
                onChanged: (value) {
                  payType = "Alipay";
                  setState(() {
                    if (value) {
                      currentSelectedPayType = 1;
                    }
                  });
                },
              )
            ],
          ),
          Divider(height: 1, color: Colours.grayA3A0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                height: 45,
                child: Row(
                  children: [
                    Icon(
                      payBankCard,
                      color: Color(0xFFF7BD24),
                    ),
                    SizedBox(width: 22),
                    Text(
                      "银行卡支付",
                      style:
                          TextStyle(fontSize: 14, color: Colours.textBlack32),
                    )
                  ],
                ),
              ),
              RedCircleCheckBox(
                value: currentSelectedPayType == 2,
                onChanged: (value) {
                  payType = "BankPay";
                  setState(() {
                    if (value) {
                      currentSelectedPayType = 2;
                    }
                  });
                },
              )
            ],
          )*/
        ],
      ),
    );
  }

  Widget _buildItem(String title, String rightText,
      {bool isRequired = false,
      Color rightTextColor = Colours.textGrayA3A0,
      bool rightEdit = false,
      TextEditingController controller}) {
    return Container(
      height: 45,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colours.textBlack32),
              ),
              Visibility(
                visible: isRequired,
                child: Text(
                  "*",
                  style: TextStyle(color: Colours.mainRed, fontSize: 18),
                ),
              )
            ],
          ),
          rightEdit
              ? Expanded(
                  child: TextField(
                    textAlign: TextAlign.end,
                    controller: controller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      fillColor: Color(0xFFF0F0F0),
                      hintText: rightText,
                      hintStyle:
                          TextStyle(color: Color(0xFFA7A5A5), fontSize: 12),
                    ),
                    onSubmitted: (s) {},
                  ),
                )
              : Text(
                  rightText,
                  style: TextStyle(fontSize: 12, color: rightTextColor),
                )
        ],
      ),
    );
  }

  _buildCarPhoto(int car) {
    if (isNormalUser && sealViewModel.sealModel?.status == "0") {
      return Container();
    }
    switch (car) {
      case 1:
        if (!isNormalUser && sealViewModel.sealModel?.status == "0") {
          return Container();
        }
        break;
      case 2:
        if (!isNormalUser && sealViewModel.sealModel?.status == "0") {
          return Container();
        }
        break;
      case 3:
        if (!isNormalUser && sealViewModel.sealModel?.status == "0") {
          return Container();
        }
        break;
    }
    //car 0 是车辆照片
    //car 1是油罐车照片
    //car 2是验油照片
    //car 3是榜单照片
    String carImage = "";
    String carCheckImgUrl = "";
    String oilCheckImgUrl = "";
    String poundImgUrl = "";
    if (isEdit && isNormalUser) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("carImgUrl" == element.dictValue) {
          carImage = element.dictLabel;
        }
        if ("carCheckImgUrl" == element.dictValue) {
          carCheckImgUrl = element.dictLabel;
        }
        if ("oilCheckImgUrl" == element.dictValue) {
          oilCheckImgUrl = element.dictLabel;
        }
        if ("poundImgUrl" == element.dictValue) {
          poundImgUrl = element.dictLabel;
        }
      });
    } else {
      carImage = sealViewModel.sealModel?.carImgUrl;
      carCheckImgUrl = sealViewModel.sealModel?.carCheckImgUrl;
      oilCheckImgUrl = sealViewModel.sealModel?.oilCheckImgUrl;
      poundImgUrl = sealViewModel.sealModel?.poundImgUrl;
    }

    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              car == 0
                  ? "车辆照片"
                  : car == 1
                      ? "验罐照片"
                      : car == 2
                          ? "验油照片"
                          : "磅单照片",
              style: TextStyle(
                  fontSize: 14,
                  color: Colours.textBlack32,
                  fontWeight: FontWeight.bold)),
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: isNormalUser ||
                    (sealViewModel.sealModel?.status != "0" && car == 0) ||
                    (sealViewModel.sealModel?.status == "2")
                ? Container(
                    child:
                        (car == 0 && carImage != null && carImage.isNotEmpty) ||
                                (car == 1 &&
                                    carCheckImgUrl != null &&
                                    carCheckImgUrl.isNotEmpty) ||
                                (car == 2 &&
                                    oilCheckImgUrl != null &&
                                    oilCheckImgUrl.isNotEmpty) ||
                                (car == 3 &&
                                    poundImgUrl != null &&
                                    poundImgUrl.isNotEmpty)
                            ? Visibility(
                                visible: (car == 0 &&
                                        carImage != null &&
                                        carImage.isNotEmpty) ||
                                    (car == 1 &&
                                        carCheckImgUrl != null &&
                                        carCheckImgUrl.isNotEmpty) ||
                                    (car == 2 &&
                                        oilCheckImgUrl != null &&
                                        oilCheckImgUrl.isNotEmpty) ||
                                    (car == 3 &&
                                        poundImgUrl != null &&
                                        poundImgUrl.isNotEmpty),
                                child: InkWell(
                                  onTap: () {
                                    String carUrl = "";
                                    switch (car) {
                                      case 0:
                                        carUrl = carImage;
                                        break;
                                      case 1:
                                        carUrl = carCheckImgUrl;
                                        break;
                                      case 2:
                                        carUrl = oilCheckImgUrl;
                                        break;
                                      case 3:
                                        carUrl = poundImgUrl;
                                        break;
                                    }
                                    _showCheckPicDialog(carUrl);
                                  },
                                  child: NetworkCus(
                                      url: car == 0
                                          ? carImage
                                          : car == 1
                                              ? carCheckImgUrl
                                              : car == 2
                                                  ? oilCheckImgUrl
                                                  : poundImgUrl),
                                ),
                              )
                            : NetworkCus(),
                  )
                : InkWell(
                    //修改
                    onTap: () async {
                      if (car == 0) {
                        var image = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 80,
                            maxHeight: 1080,
                            maxWidth: 1920);
                        selectCarPhotoLocal = image.path;
                      } else if (car == 1) {
                        var image = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                            maxHeight: 1080,
                            maxWidth: 1920);
                        selectGuanPhotoLocal = image.path;
                      } else if (car == 2) {
                        var image = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                            maxHeight: 1080,
                            maxWidth: 1920);
                        selectOilCheckPhotoLocal = image.path;
                      } else if (car == 3) {
                        var image = await ImagePicker().pickImage(
                            source: ImageSource.camera,
                            imageQuality: 80,
                            maxHeight: 1080,
                            maxWidth: 1920);
                        selectpoundImgUrlPhotoLocal = image.path;
                      }
                      setState(() {});
                      commonViewModel.uploadFile(
                          car == 0
                              ? selectCarPhotoLocal
                              : car == 1
                                  ? selectGuanPhotoLocal
                                  : car == 2
                                      ? selectOilCheckPhotoLocal
                                      : selectpoundImgUrlPhotoLocal, (path) {
                        switch (car) {
                          case 0:
                            sealViewModel.sealModel.carImgUrl = path;
                            break;
                          case 1:
                            sealViewModel.sealModel.carCheckImgUrl = path;
                            break;
                          case 2:
                            sealViewModel.sealModel.oilCheckImgUrl = path;
                            break;
                          case 3:
                            sealViewModel.sealModel.poundImgUrl = path;
                            break;
                        }
                      });
                    },
                    child: Container(
                      color: Colours.bg,
                      height: 150,
                      width: double.infinity,
                      alignment: Alignment.center,
                      //此处修改
                      child: (car == 0 && selectCarPhotoLocal.isEmpty) ||
                              (car == 1 && selectGuanPhotoLocal.isEmpty) ||
                              (car == 2 && selectOilCheckPhotoLocal.isEmpty) ||
                              (car == 3 && selectpoundImgUrlPhotoLocal.isEmpty)
                          ? Image.asset(
                              "resource/images/icon_add.png",
                              width: 36,
                              height: 30,
                            )
                          : Image.file(File(car == 0
                              ? selectCarPhotoLocal
                              : car == 1
                                  ? selectGuanPhotoLocal
                                  : car == 2
                                      ? selectOilCheckPhotoLocal
                                      : selectpoundImgUrlPhotoLocal)),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  //验罐视频
  _buildOilCarVideo() {
    if (isNormalUser && sealViewModel.sealModel?.status == "0") {
      return Container();
    }
    if (!isNormalUser && sealViewModel.sealModel?.status == "0") {
      return Container();
    }
    String videoUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("carCheckVideoUrl" == element.dictValue) {
          videoUrl = element.dictLabel;
        }
      });
    } else {
      videoUrl = sealViewModel.sealModel?.carCheckVideoUrl ?? "";
    }
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("验罐视频",
              style: TextStyle(
                  fontSize: 14,
                  color: Colours.textBlack32,
                  fontWeight: FontWeight.bold)),
          //铅封人员 或者 状态等于进行中 是:{检查视频初始化是否完成 是:加载成功 否:显示默认图片} 否:{}
          isNormalUser || sealViewModel.sealModel?.status == "2"
              ?       
          InkWell(
            onTap: (){
              showDialog(
                  useSafeArea: false,
                  context: context, builder: (ctx){
                return VideoPlayShowDialog(path: videoUrl, isLocal: false);
              });
            },
            child:
                     Container(
                        width: double.infinity,
                        height: 150,
                        child: Image.asset(
                          "resource/images/seal_noVio.jpg",
                        ),
          ) )
              : InkWell(
                  onTap: () async {
                    var video = await ImagePicker().pickVideo(
                      source: ImageSource.camera,
                    );
                    selectOilCheckVideoLocal = video.path;
                    _controllerLocalOilCarVideo = VideoPlayerController.file(
                        File(selectOilCheckVideoLocal))
                      ..addListener(() {
                        if (mounted) setState(() {});
                      })
                      ..initialize().then((_) {
                        _chewieOilLocalCarController = ChewieController(
                            videoPlayerController: _controllerLocalOilCarVideo,
                            autoPlay: false,
                            looping: false,
                            showOptions: false,
                            fullScreenByDefault: true);
                      });
                    commonViewModel.uploadFile(selectOilCheckVideoLocal,
                        (path) {
                      sealViewModel.sealModel.carCheckVideoUrl = path;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    color: Colours.bg,
                    height: 150,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: selectOilCheckVideoLocal.isEmpty
                        ? Image.asset(
                            "resource/images/icon_image_upload.png",
                            height: 30,
                            width: 36,
                          )
                        : Chewie(
                            controller: _chewieOilLocalCarController,
                          ),
                  ),
                ),
        ],
      ),
    );
  }

  //出厂视频
  _buildCarVideo() {
    if (isNormalUser && sealViewModel.sealModel?.status == "0") {
      return Container();
    }
    if (!isNormalUser && sealViewModel.sealModel?.status == "0") {
      return Container();
    }
    String videoUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("carVideoUrl" == element.dictValue) {
          videoUrl = element.dictLabel;
        }
      });
    } else {
      videoUrl = sealViewModel.sealModel?.carVideoUrl ?? "";
    }
    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("出厂视频",
              style: TextStyle(
                  fontSize: 14,
                  color: Colours.textBlack32,
                  fontWeight: FontWeight.bold)),
          isNormalUser || sealViewModel.sealModel?.status == "2"
              ? InkWell(
              onTap: (){
                showDialog(
                    useSafeArea: false,
                    context: context, builder: (ctx){
                  return VideoPlayShowDialog(path: videoUrl, isLocal: false);
                });
              },
              child:
              Container(
                width: double.infinity,
                height: 150,
                child: Image.asset(
                  "resource/images/seal_noVio.jpg",
                ),
              ) )
              : InkWell(
                  onTap: () async {
                    var video = await ImagePicker().pickVideo(
                      source: ImageSource.camera,
                    );
                    selectCarVideoLocal = video.path;
                    _controllerLocal =
                        VideoPlayerController.file(File(selectCarVideoLocal))
                          ..addListener(() {
                            if (mounted) setState(() {});
                          })
                          ..initialize().then((_) {
                            _chewieCarLocalController = ChewieController(
                                videoPlayerController: _controllerLocal,
                                autoPlay: false,
                                looping: false,
                                showOptions: false,
                                fullScreenByDefault: true);
                          });
                    commonViewModel.uploadFile(selectCarVideoLocal, (path) {
                      sealViewModel.sealModel.carVideoUrl = path;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    color: Colours.bg,
                    height: 150,
                    width: double.infinity,
                    alignment: Alignment.center,
                    child: selectCarVideoLocal.isEmpty
                        ? Image.asset(
                            "resource/images/icon_image_upload.png",
                            height: 30,
                            width: 36,
                          )
                        : Chewie(
                            controller: _chewieCarLocalController,
                          ),
                  ),
                ),
        ],
      ),
    );
  }

  _buildSealPhoto() {
    if (!isEdit && isNormalUser && sealViewModel.sealModel?.status != "2") {
      return Container();
    }
    if (!isNormalUser && sealViewModel.sealModel?.status == "0") {
      return Container();
    }
    initSealPhotoList();
    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("铅封照片",
              style: TextStyle(
                  fontSize: 14,
                  color: Colours.textBlack32,
                  fontWeight: FontWeight.bold)),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: GridView.count(
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 3 / 5,
              crossAxisSpacing: 12,
              children: sealPhotoList.map((e) {
                return Column(
                  children: [
                    isNormalUser || sealViewModel.sealModel?.status == "2"
                        ? Container(
                            child: InkWell(
                              onTap: () {
                                _showCheckPicDialog(e.url);
                              },
                              child: NetworkCus(
                                width:
                                    (ScreenUtil(context).screenWidth - 40) / 2,
                                url: e.url,
                                fit: BoxFit.cover,
                              ),
                            ),
                          )
                        : InkWell(
                            child: Container(
                              height: 120,
                              color: Colours.bg,
                              alignment: Alignment.center,
                              child: e?.url?.startsWith("resource/") ?? true
                                  ? Image.asset(
                                      "resource/images/icon_image_upload.png",
                                      height: 30,
                                      width: 36,
                                    )
                                  : Image.file(File(e.url ?? "")),
                            ),
                            onTap: () {
                              selectSealImage(e.tag);
                            },
                          ),
                    SizedBox(height: 6),
                    Text(
                      e.title,
                      style:
                          TextStyle(fontSize: 12, color: Colours.textBlack32),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  _showCheckPicDialog(dynamic url) {
    return showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(color: Colors.black),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Container(
                      height: MediaQuery.of(context).size.width,
                      width: MediaQuery.of(context).size.width, //
                      child: url == null
                          ? Image.asset(
                              'resource/images/seal_noImage.jpg',
                              alignment: Alignment.center,
                              fit: BoxFit.fitWidth,
                            )
                          : PhotoView(
                              minScale: PhotoViewComputedScale.contained * 0.6,
                              maxScale: PhotoViewComputedScale.covered * 2.0,
                              initialScale: PhotoViewComputedScale.contained,
                              imageProvider: NetworkImage(url),
                            )),
                ),
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    margin: EdgeInsets.only(right: 10, top: 60),
                    child: InkWell(
                      onTap: () {
                        Navigator.pop(context);
                      },
                      child: Image.asset(
                        "resource/images/icon_shanchu.png",
                        width: 35,
                      ),
                    ),
                  ),
                )
              ],
            ),
          );
        });
  }

  void showTimeSelect() {
    var weekday = ["星期日", "星期一", "星期二", "星期三", "星期四", "星期五", "星期六"];
    int weekIndex = (DateTime.now().weekday);
    String day1 = formatDate(DateTime.now(), ['yyyy', '-', 'mm', '-', 'dd']);
    String day2 = formatDate(
        DateTime.now().add(Duration(days: 1)), ['yyyy', '-', 'mm', '-', 'dd']);
    String day3 = formatDate(
        DateTime.now().add(Duration(days: 2)), ['yyyy', '-', 'mm', '-', 'dd']);
    final date = [day1, day2, day3];
    final week = [
      weekday[(weekIndex % weekday.length) % 7],
      weekday[(weekIndex % weekday.length + 1) % 7],
      weekday[(weekIndex % weekday.length + 2) % 7]
    ];
    var list =
        List.generate(23, (index) => "${(index + 1)}:00-${(index + 2)}:00")
            .toList();
    final timeData3 = [
      [
        "今天(${weekday[(weekIndex % weekday.length) % 7]})",
        "明天(${weekday[(weekIndex % weekday.length + 1) % 7]})",
        "后天(${weekday[(weekIndex % weekday.length + 2) % 7]})"
      ],
      list,
    ];

    Widget _cancelButton = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      margin: const EdgeInsets.only(left: 22),
      child: Text(
        '取消',
        style: TextStyle(fontSize: 14, color: Colours.textBlack32),
      ),
    );

    Widget _commitButton = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      margin: const EdgeInsets.only(right: 22),
      child: Text(
        '确定',
        style: TextStyle(fontSize: 14, color: Colours.textBlack32),
      ),
    );

    var pickerStyle = PickerStyle(
      cancelButton: _cancelButton,
      commitButton: _commitButton,
      title: Center(
        child: Text(
          "选择预计出厂时间",
          style: TextStyle(
              color: Colours.textBlack32,
              fontSize: 16,
              fontWeight: FontWeight.bold),
        ),
      ),
      textColor: Colours.textBlack32,
    );

    Pickers.showMultiPicker(
      context,
      pickerStyle: pickerStyle,
      data: timeData3,
      onConfirm: (p, position) {
        selectCarTimeSave = "${date[position.first]} ${list[position.last]}";
        var now = DateTime.now();
        var hour = int.parse(list[position.last].split("-")[1].split(":")[0]);
        var select = DateTime.parse(date[position.first]);
        var selectDateTime =
            DateTime(select.year, select.month, select.day, hour);
        sealViewModel.sealModel?.planDeliveryDate = selectCarTimeSave;
        if (selectDateTime.isBefore(now)) {
          Fluttertoast.showToast(msg: '出厂时间必须大于当时时间');
          return;
        } else {
          selectCarTime =
              "${date[position.first]}(${week[position.first]}) ${list[position.last]}";
          setState(() {});
        }
      },
    );
  }

  void showCarFactorySelect() {
    List<String> list =
        commonViewModel.truckPointlList.map((e) => e.dictLabel).toList();
    showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return CarFactorySheet(
            pickerData: list,
            currentIndex:
                selectCarFactory.isEmpty ? 0 : list.indexOf(selectCarFactory),
            callback: (value) {
              setState(() {
                selectCarFactory = list[value];
                sealPrice = commonViewModel.truckPointlList[value].remark;
                if (isModify) {
                  sealViewModel.sealModel?.truckPoint = selectCarFactory;
                }
              });
            },
          );
        });
  }

  bool updateSeal(bool changeStatus) {
    if (!isNormalUser) {
      // 铅封人员
      // if (selectCarPhotoLocal.isEmpty &&
      //     sealViewModel.sealModel?.status == "0") {
      //   Fluttertoast.showToast(msg: "请上传车辆照片");
      //   return false;
      // }
      if (sealViewModel.sealModel?.status == "1") {
        if (selectCarVideoLocal.isEmpty) {
          Fluttertoast.showToast(msg: "请上传出厂视频");
          return false;
        }
        if (selectOilCheckVideoLocal.isEmpty) {
          Fluttertoast.showToast(msg: "请上传验罐视频");
          return false;
        }

        if (selectGuanPhotoLocal.isEmpty) {
          Fluttertoast.showToast(msg: "请上传验罐照片");
          return false;
        }
        if (selectOilCheckPhotoLocal.isEmpty) {
          Fluttertoast.showToast(msg: "请上传验油照片");
          return false;
        }
        if (
            // selectUpPhotoLocal.isEmpty ||
            selectUpFullPhotoLocal.isEmpty ||
                selectDownPhotoLocal.isEmpty ||
                selectDownFullPhotoLocal.isEmpty ||
                selectFrontPhotoLocal.isEmpty ||
                selectFrontFullPhotoLocal.isEmpty ||
                selectLeftPhotoLocal.isEmpty ||
                selectLeftFullPhotoLocal.isEmpty ||
                selectRightPhotoLocal.isEmpty ||
                selectRightFullPhotoLocal.isEmpty ||
                selectNo6ImgUrlPhotoLocal.isEmpty ||
                selectNo7ImgUrlPhotoLocal.isEmpty ||
                selectNo8ImgUrlPhotoLocal.isEmpty ||
                selectNo6ImgFullUrlPhotoLocal.isEmpty ||
                selectNo7ImgFullUrlPhotoLocal.isEmpty ||
                selectNo8ImgFullUrlPhotoLocal.isEmpty) {
          Fluttertoast.showToast(msg: "请完善铅封照片");
          return false;
        }
      }
    } else {
      String carNo = carNoEditingController.text;
      String ownerPhone = ownerPhoneEditingController.text;
      String driverPhone = driverPhoneEditingController.text;
      if (carNo.isNotEmpty) {
        if (!RegExp(
                r"^[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领A-Z]{1}[A-Z]{1}[A-Z0-9]{4}[A-Z0-9挂学警港澳]{1}$")
            .hasMatch(carNo)) {
          Fluttertoast.showToast(msg: "请输入正确的车牌号");
          return false;
        } else {
          sealViewModel.sealModel.carNo = carNo;
        }
      }
      if (driverPhone.isNotEmpty) {
        if (!Unity.checkPhone(driverPhone)) {
          Fluttertoast.showToast(msg: "请输入正确的司机电话");
          return false;
        } else {
          sealViewModel.sealModel.driverMobile = driverPhone;
        }
      }
      if (ownerPhone.isNotEmpty) {
        if (!Unity.checkPhone(ownerPhone)) {
          Fluttertoast.showToast(msg: "请输入正确的货主电话");
          return false;
        } else {
          sealViewModel.sealModel.shipperMobile = ownerPhone;
        }
      }
    }

    sealViewModel.updateSeal(sealViewModel.sealModel, changeStatus, (result) {
      if (result) {
        Fluttertoast.showToast(msg: "操作成功");
        if (!isNormalUser) {
          fire(RefreshSealListEvent());
          pop();
        }
      } else {
        Fluttertoast.showToast(msg: "操作失败");
      }
    });
    return true;
  }

  void saveSeal() {
    if (selectCarFactory.isEmpty) {
      Fluttertoast.showToast(msg: "请选择装车地点");
      return;
    }
    String carNo = carNoEditingController.text;
    if (carNo.isEmpty ||
        !RegExp(r"^[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领A-Z]{1}[A-Z]{1}[A-Z0-9]{4}[A-Z0-9挂学警港澳]{1}$")
            .hasMatch(carNo)) {
      Fluttertoast.showToast(msg: "请输入正确的车牌号");
      return;
    }
    String ownerPhone = ownerPhoneEditingController.text;
    if (ownerPhone.isEmpty ||
        !Unity.checkPhone(ownerPhone) ||
        ownerPhone.length != 11) {
      Fluttertoast.showToast(msg: "请输入正确的货主电话");
      return;
    }

    String driverPhone = driverPhoneEditingController.text;
    if (driverPhone.isEmpty ||
        !Unity.checkPhone(driverPhone) ||
        driverPhone.length != 11) {
      Fluttertoast.showToast(msg: "请输入正确的司机电话");
      return;
    }

    sealViewModel.saveSeal(selectCarFactory, selectCarTimeSave, carNo,
        ownerPhone, driverPhone, sealPrice, payType, (result) {
      if (result) {
        Fluttertoast.showToast(msg: "发布成功");
        pushNamedPage(sealPayResultRoute, arg: true).whenComplete(() => pop());
      } else {
        Fluttertoast.showToast(msg: "发布失败");
      }
    });
  }

  @override
  void dispose() {
    _controllerLocal?.dispose();
    _controllerLocalOilCarVideo?.dispose();
    _chewieCarLocalController?.dispose();
    _chewieOilLocalCarController?.dispose();
    payListen?.cancel();
    super.dispose();
  }

  void initSealPhotoList() {
    if (!isNeedRefreshSealPhoto) {
      return;
    }
    sealPhotoList.clear();
    String no1ImgUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no1ImgUrl" == element.dictValue) {
          no1ImgUrl = element.dictLabel;
        }
      });
    } else {
      no1ImgUrl = sealViewModel.sealModel?.no1ImgUrl;
    }
    sealPhotoList
        .add(SealPhotoModel("1号口编号", no1ImgUrl, SealPhotoModel.TAG_UP));

    String no1ImgFullUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no1ImgFullUrl" == element.dictValue) {
          no1ImgFullUrl = element.dictLabel;
        }
      });
    } else {
      no1ImgFullUrl = sealViewModel.sealModel?.no1ImgUrl;
    }
    sealPhotoList.add(
        SealPhotoModel("1号口全景", no1ImgFullUrl, SealPhotoModel.TAG_UP_FULL));

    String no2ImgUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no2ImgUrl" == element.dictValue) {
          no2ImgUrl = element.dictLabel;
        }
      });
    } else {
      no2ImgUrl = sealViewModel.sealModel?.no2ImgUrl;
    }
    sealPhotoList
        .add(SealPhotoModel("2号口编号", no2ImgUrl, SealPhotoModel.TAG_DOWN));

    String no2ImgFullUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no2ImgFullUrl" == element.dictValue) {
          no2ImgFullUrl = element.dictLabel;
        }
      });
    } else {
      no2ImgFullUrl = sealViewModel.sealModel?.no2ImgFullUrl;
    }

    sealPhotoList.add(
        SealPhotoModel("2号口全景", no2ImgFullUrl, SealPhotoModel.TAG_DOWN_FULL));

    String no3ImgUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no3ImgUrl" == element.dictValue) {
          no3ImgUrl = element.dictLabel;
        }
      });
    } else {
      no3ImgUrl = sealViewModel.sealModel?.no3ImgUrl;
    }
    sealPhotoList
        .add(SealPhotoModel("3号口编号", no3ImgUrl, SealPhotoModel.TAG_FRONT));

    String no3ImgFullUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no3ImgFullUrl" == element.dictValue) {
          no3ImgFullUrl = element.dictLabel;
        }
      });
    } else {
      no3ImgFullUrl = sealViewModel.sealModel?.no3ImgFullUrl;
    }
    sealPhotoList.add(
        SealPhotoModel("3号口全景", no3ImgFullUrl, SealPhotoModel.TAG_FRONT_FULL));

    String no4ImgUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no4ImgUrl" == element.dictValue) {
          no4ImgUrl = element.dictLabel;
        }
      });
    } else {
      no4ImgUrl = sealViewModel.sealModel?.no4ImgUrl;
    }
    sealPhotoList
        .add(SealPhotoModel("4号口编号", no4ImgUrl, SealPhotoModel.TAG_LEFT));

    String no4ImgFullUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no4ImgFullUrl" == element.dictValue) {
          no4ImgFullUrl = element.dictLabel;
        }
      });
    } else {
      no4ImgFullUrl = sealViewModel.sealModel?.no4ImgFullUrl;
    }
    sealPhotoList.add(
        SealPhotoModel("4号口全景", no4ImgFullUrl, SealPhotoModel.TAG_LEFT_FULL));

    String no5ImgUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no5ImgUrl" == element.dictValue) {
          no5ImgUrl = element.dictLabel;
        }
      });
    } else {
      no5ImgUrl = sealViewModel.sealModel?.no5ImgUrl;
    }
    sealPhotoList
        .add(SealPhotoModel("5号口编号", no5ImgUrl, SealPhotoModel.TAG_RIGHT));

    String no5ImgFullUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no5ImgFullUrl" == element.dictValue) {
          no5ImgFullUrl = element.dictLabel;
        }
      });
    } else {
      no5ImgFullUrl = sealViewModel.sealModel?.no5ImgFullUrl;
    }
    sealPhotoList.add(
        SealPhotoModel("5号口全景", no5ImgFullUrl, SealPhotoModel.TAG_RIGHT_FULL));

    String no6ImgUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no6ImgUrl" == element.dictValue) {
          no6ImgUrl = element.dictLabel;
        }
      });
    } else {
      no6ImgUrl = sealViewModel.sealModel?.no6ImgUrl;
    }
    sealPhotoList.add(SealPhotoModel("6号口编号", no6ImgUrl, SealPhotoModel.no6));

    String no6ImgFullUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no6ImgFullUrl" == element.dictValue) {
          no6ImgFullUrl = element.dictLabel;
        }
      });
    } else {
      no6ImgFullUrl = sealViewModel.sealModel?.no6ImgFullUrl;
    }
    sealPhotoList
        .add(SealPhotoModel("6号口全景", no6ImgFullUrl, SealPhotoModel.no6_FULL));

    String no7ImgUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no7ImgUrl" == element.dictValue) {
          no7ImgUrl = element.dictLabel;
        }
      });
    } else {
      no7ImgUrl = sealViewModel.sealModel?.no7ImgUrl;
    }
    sealPhotoList.add(SealPhotoModel("7号口编号", no7ImgUrl, SealPhotoModel.no7));

    String no7ImgFullUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no7ImgFullUrl" == element.dictValue) {
          no7ImgFullUrl = element.dictLabel;
        }
      });
    } else {
      no7ImgFullUrl = sealViewModel.sealModel?.no7ImgFullUrl;
    }
    sealPhotoList
        .add(SealPhotoModel("7号口全景", no7ImgFullUrl, SealPhotoModel.no7_FULL));

    String no8ImgUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no8ImgUrl" == element.dictValue) {
          no8ImgUrl = element.dictLabel;
        }
      });
    } else {
      no8ImgUrl = sealViewModel.sealModel?.no8ImgUrl;
    }
    sealPhotoList.add(SealPhotoModel("8号口编号", no8ImgUrl, SealPhotoModel.no8));

    String no8ImgFullUrl = "";
    if (isEdit) {
      var sealServicelList = commonViewModel.sealServicelList;
      sealServicelList.forEach((element) {
        if ("no8ImgFullUrl" == element.dictValue) {
          no8ImgFullUrl = element.dictLabel;
        }
      });
    } else {
      no8ImgFullUrl = sealViewModel.sealModel?.no7ImgFullUrl;
    }
    sealPhotoList
        .add(SealPhotoModel("8号口全景", no8ImgFullUrl, SealPhotoModel.no8_FULL));

    if (!isNormalUser && sealViewModel.sealModel?.status == "1") {
      sealPhotoList
          .map((e) => e.url = "resource/images/icon_image_upload.png")
          .toList();
    }
  }

  void selectSealImage(String tag) async {
    var image = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxHeight: 1080,
        maxWidth: 1920);

    String localPath = image.path;
    setSealImage(tag, localPath, false);

    commonViewModel.uploadFile(localPath, (path) {
      setSealImage(tag, path, true);
    });
  }

  changeSealImageList(String tag, String url) {
    sealPhotoList.forEach((element) {
      if (element.tag == tag) {
        element.url = url;
      }
    });
  }

  setSealImage(String tag, String url, bool isNet) {
    switch (tag) {
      case SealPhotoModel.TAG_UP:
        if (isNet) {
          sealViewModel.sealModel.no1ImgUrl = url;
        } else {
          selectUpPhotoLocal = url;
        }
        break;

      case SealPhotoModel.TAG_UP_FULL:
        if (isNet) {
          sealViewModel.sealModel.no1ImgFullUrl = url;
        } else {
          selectUpFullPhotoLocal = url;
        }
        break;

      case SealPhotoModel.TAG_DOWN:
        if (isNet) {
          sealViewModel.sealModel.no2ImgUrl = url;
        } else {
          selectDownPhotoLocal = url;
        }
        break;

      case SealPhotoModel.TAG_DOWN_FULL:
        if (isNet) {
          sealViewModel.sealModel.no2ImgFullUrl = url;
        } else {
          selectDownFullPhotoLocal = url;
        }
        break;

      case SealPhotoModel.TAG_FRONT:
        if (isNet) {
          sealViewModel.sealModel.no3ImgUrl = url;
        } else {
          selectFrontPhotoLocal = url;
        }
        break;

      case SealPhotoModel.TAG_FRONT_FULL:
        if (isNet) {
          sealViewModel.sealModel.no3ImgFullUrl = url;
        } else {
          selectFrontFullPhotoLocal = url;
        }
        break;

      case SealPhotoModel.TAG_LEFT:
        if (isNet) {
          sealViewModel.sealModel.no4ImgUrl = url;
        } else {
          selectLeftPhotoLocal = url;
        }
        break;

      case SealPhotoModel.TAG_LEFT_FULL:
        if (isNet) {
          sealViewModel.sealModel.no4ImgFullUrl = url;
        } else {
          selectLeftFullPhotoLocal = url;
        }
        break;

      case SealPhotoModel.TAG_RIGHT:
        if (isNet) {
          sealViewModel.sealModel.no5ImgUrl = url;
        } else {
          selectRightPhotoLocal = url;
        }
        break;

      case SealPhotoModel.TAG_RIGHT_FULL:
        if (isNet) {
          sealViewModel.sealModel.no5ImgFullUrl = url;
        } else {
          selectRightFullPhotoLocal = url;
        }
        break;
      case SealPhotoModel.no6:
        if (isNet) {
          sealViewModel.sealModel.no6ImgUrl = url;
        } else {
          selectNo6ImgUrlPhotoLocal = url;
        }
        break;
      case SealPhotoModel.no6_FULL:
        if (isNet) {
          sealViewModel.sealModel.no6ImgFullUrl = url;
        } else {
          selectNo6ImgFullUrlPhotoLocal = url;
        }
        break;

      case SealPhotoModel.no7:
        if (isNet) {
          sealViewModel.sealModel.no7ImgUrl = url;
        } else {
          selectNo7ImgUrlPhotoLocal = url;
        }
        break;

      case SealPhotoModel.no7_FULL:
        if (isNet) {
          sealViewModel.sealModel.no7ImgFullUrl = url;
        } else {
          selectNo7ImgFullUrlPhotoLocal = url;
        }
        break;

      case SealPhotoModel.no8:
        if (isNet) {
          sealViewModel.sealModel.no8ImgUrl = url;
        } else {
          selectNo8ImgUrlPhotoLocal = url;
        }
        break;
      case SealPhotoModel.no8_FULL:
        if (isNet) {
          sealViewModel.sealModel.no8ImgFullUrl = url;
        } else {
          selectNo8ImgFullUrlPhotoLocal = url;
        }
        break;
    }
    isNeedRefreshSealPhoto = false;
    if (!isNet) {
      setState(() {
        changeSealImageList(tag, url);
      });
    }
  }

  Future<void> pay() async {
    // SharedPreferenceUtil.isAuth().then((value) async {
    //   if (value) {
    //
    //   } else {
    //     pushNamedPage(idAuthRoute, arg: {"fromHome": true});
    //   }
    // });
    if (selectCarFactory.isEmpty) {
      Fluttertoast.showToast(msg: "请选择装车地点");
      return;
    }
    if (selectCarTime.isEmpty) {
      Fluttertoast.showToast(msg: "请选择出厂时间");
      return;
    }
    String carNo = carNoEditingController.text;
    if (carNo.isEmpty ||
        !RegExp(r"^[京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼使领A-Z]{1}[A-Z]{1}[A-Z0-9]{4}[A-Z0-9挂学警港澳]{1}$")
            .hasMatch(carNo)) {
      Fluttertoast.showToast(msg: "请输入正确的车牌号");
      return;
    }
    String ownerPhone = ownerPhoneEditingController.text;
    if (ownerPhone.isEmpty ||
        !Unity.checkPhone(ownerPhone) ||
        ownerPhone.length != 11) {
      Fluttertoast.showToast(msg: "请输入正确的货主电话");
      return;
    }

    String driverPhone = driverPhoneEditingController.text;
    if (driverPhone.isEmpty ||
        !Unity.checkPhone(driverPhone) ||
        driverPhone.length != 11) {
      Fluttertoast.showToast(msg: "请输入正确的司机电话");
      return;
    }

    // if (driverPhone == ownerPhone) {
    //   Fluttertoast.showToast(msg: "货主电话和司机电话不可重复");
    //   return;
    // }

    bool pay = await Unity.payWechat(sealPrice);
  }
}
