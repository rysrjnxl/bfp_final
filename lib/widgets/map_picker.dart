import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({super.key});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const LatLng _municipalCenter = LatLng(14.18430, 120.79640);

  static final LatLngBounds _municipalBounds = LatLngBounds(
    const LatLng(14.1400, 120.7650),
    const LatLng(14.2250, 120.8400),
  );

  static const List<LatLng> _municipalPolygon = [
    LatLng(14.183532, 120.821550),
    LatLng(14.183939, 120.821258),
    LatLng(14.184016, 120.820961),
    LatLng(14.184018, 120.820746),
    LatLng(14.184178, 120.820409),
    LatLng(14.184581, 120.819895),
    LatLng(14.185221, 120.819672),
    LatLng(14.185246, 120.819263),
    LatLng(14.185718, 120.819228),
    LatLng(14.185980, 120.819429),
    LatLng(14.186393, 120.819261),
    LatLng(14.186391, 120.818916),
    LatLng(14.186691, 120.818684),
    LatLng(14.187186, 120.818568),
    LatLng(14.187623, 120.818594),
    LatLng(14.188005, 120.818715),
    LatLng(14.188190, 120.818751),
    LatLng(14.188468, 120.818950),
    LatLng(14.188745, 120.819008),
    LatLng(14.188866, 120.818868),
    LatLng(14.188975, 120.818897),
    LatLng(14.189291, 120.819035),
    LatLng(14.189482, 120.818851),
    LatLng(14.189696, 120.818724),
    LatLng(14.189949, 120.818658),
    LatLng(14.190152, 120.818528),
    LatLng(14.190460, 120.818230),
    LatLng(14.190757, 120.818017),
    LatLng(14.190969, 120.818017),
    LatLng(14.191196, 120.817955),
    LatLng(14.191399, 120.817794),
    LatLng(14.191552, 120.817552),
    LatLng(14.191610, 120.817285),
    LatLng(14.191780, 120.817013),
    LatLng(14.192081, 120.816877),
    LatLng(14.192255, 120.816558),
    LatLng(14.192409, 120.816468),
    LatLng(14.192540, 120.816329),
    LatLng(14.192680, 120.816041),
    LatLng(14.192937, 120.815905),
    LatLng(14.193029, 120.815746),
    LatLng(14.193185, 120.815573),
    LatLng(14.193366, 120.815468),
    LatLng(14.193728, 120.815424),
    LatLng(14.193921, 120.815506),
    LatLng(14.194126, 120.815478),
    LatLng(14.194314, 120.815309),
    LatLng(14.194556, 120.815160),
    LatLng(14.194893, 120.815019),
    LatLng(14.195094, 120.814849),
    LatLng(14.195331, 120.814723),
    LatLng(14.195607, 120.814726),
    LatLng(14.195883, 120.814655),
    LatLng(14.196443, 120.814514),
    LatLng(14.196669, 120.814346),
    LatLng(14.197061, 120.814033),
    LatLng(14.197284, 120.813744),
    LatLng(14.197506, 120.813529),
    LatLng(14.197753, 120.813374),
    LatLng(14.198087, 120.813188),
    LatLng(14.198353, 120.813026),
    LatLng(14.198607, 120.812944),
    LatLng(14.198873, 120.812905),
    LatLng(14.199139, 120.812724),
    LatLng(14.199460, 120.812709),
    LatLng(14.199873, 120.812859),
    LatLng(14.200053, 120.812957),
    LatLng(14.200232, 120.812951),
    LatLng(14.200397, 120.812928),
    LatLng(14.200563, 120.812967),
    LatLng(14.200581, 120.812855),
    LatLng(14.200857, 120.812605),
    LatLng(14.201086, 120.812312),
    LatLng(14.201227, 120.811994),
    LatLng(14.201342, 120.811880),
    LatLng(14.201591, 120.811872),
    LatLng(14.201809, 120.811765),
    LatLng(14.202118, 120.811582),
    LatLng(14.202307, 120.811301),
    LatLng(14.202443, 120.811049),
    LatLng(14.202595, 120.810959),
    LatLng(14.202753, 120.810943),
    LatLng(14.202977, 120.811063),
    LatLng(14.203273, 120.811102),
    LatLng(14.203395, 120.811066),
    LatLng(14.203504, 120.810966),
    LatLng(14.203539, 120.810836),
    LatLng(14.203608, 120.810749),
    LatLng(14.203726, 120.810708),
    LatLng(14.203851, 120.810717),
    LatLng(14.204104, 120.810669),
    LatLng(14.204323, 120.810572),
    LatLng(14.204490, 120.810514),
    LatLng(14.204672, 120.810555),
    LatLng(14.204806, 120.810734),
    LatLng(14.204916, 120.810926),
    LatLng(14.205114, 120.810992),
    LatLng(14.205518, 120.811029),
    LatLng(14.206071, 120.810780),
    LatLng(14.206436, 120.810585),
    LatLng(14.206571, 120.810446),
    LatLng(14.206573, 120.810238),
    LatLng(14.206908, 120.809873),
    LatLng(14.207240, 120.809444),
    LatLng(14.207539, 120.809390),
    LatLng(14.207796, 120.809430),
    LatLng(14.208007, 120.809414),
    LatLng(14.208129, 120.809255),
    LatLng(14.208278, 120.809103),
    LatLng(14.208354, 120.808914),
    LatLng(14.208511, 120.808222),
    LatLng(14.208448, 120.807867),
    LatLng(14.208504, 120.807683),
    LatLng(14.208599, 120.807560),
    LatLng(14.208678, 120.807500),
    LatLng(14.209199, 120.807781),
    LatLng(14.209342, 120.807796),
    LatLng(14.209471, 120.807741),
    LatLng(14.209659, 120.807697),
    LatLng(14.209829, 120.807463),
    LatLng(14.209970, 120.807413),
    LatLng(14.210066, 120.807280),
    LatLng(14.210057, 120.807091),
    LatLng(14.210052, 120.807021),
    LatLng(14.210095, 120.806904),
    LatLng(14.210138, 120.806705),
    LatLng(14.210276, 120.806384),
    LatLng(14.210477, 120.806127),
    LatLng(14.210551, 120.806079),
    LatLng(14.210912, 120.806051),
    LatLng(14.211158, 120.806143),
    LatLng(14.211596, 120.806264),
    LatLng(14.211768, 120.806164),
    LatLng(14.211863, 120.805994),
    LatLng(14.211848, 120.805765),
    LatLng(14.211838, 120.805523),
    LatLng(14.211860, 120.805270),
    LatLng(14.211951, 120.805086),
    LatLng(14.212241, 120.804821),
    LatLng(14.212497, 120.804634),
    LatLng(14.212913, 120.804439),
    LatLng(14.213052, 120.804252),
    LatLng(14.213063, 120.803902),
    LatLng(14.213069, 120.803624),
    LatLng(14.212960, 120.803438),
    LatLng(14.212954, 120.803210),
    LatLng(14.213016, 120.803066),
    LatLng(14.213259, 120.802935),
    LatLng(14.213588, 120.802701),
    LatLng(14.213771, 120.802545),
    LatLng(14.213982, 120.802492),
    LatLng(14.214337, 120.802497),
    LatLng(14.214892, 120.802421),
    LatLng(14.215394, 120.802542),
    LatLng(14.215819, 120.802495),
    LatLng(14.216288, 120.802373),
    LatLng(14.216501, 120.802338),
    LatLng(14.216659, 120.802204),
    LatLng(14.216685, 120.801978),
    LatLng(14.216601, 120.801788),
    LatLng(14.216485, 120.801576),
    LatLng(14.216451, 120.801365),
    LatLng(14.216576, 120.801148),
    LatLng(14.216792, 120.800985),
    LatLng(14.217075, 120.800842),
    LatLng(14.217148, 120.800684),
    LatLng(14.217152, 120.800519),
    LatLng(14.217416, 120.800011),
    LatLng(14.217506, 120.799931),
    LatLng(14.217658, 120.799782),
    LatLng(14.217679, 120.799531),
    LatLng(14.217763, 120.799272),
    LatLng(14.218098, 120.799098),
    LatLng(14.218234, 120.798913),
    LatLng(14.218266, 120.798771),
    LatLng(14.218184, 120.798542),
    LatLng(14.218121, 120.798380),
    LatLng(14.218076, 120.798130),
    LatLng(14.218175, 120.798001),
    LatLng(14.218504, 120.798063),
    LatLng(14.218678, 120.798217),
    LatLng(14.218880, 120.798293),
    LatLng(14.219828, 120.798171),
    LatLng(14.220178, 120.798075),
    LatLng(14.220454, 120.797947),
    LatLng(14.220861, 120.797319),
    LatLng(14.220879, 120.797103),
    LatLng(14.220914, 120.796789),
    LatLng(14.221033, 120.796560),
    LatLng(14.221387, 120.796280),
    LatLng(14.221940, 120.795952),
    LatLng(14.222267, 120.795503),
    LatLng(14.222539, 120.795035),
    LatLng(14.223073, 120.794241),
    LatLng(14.223305, 120.793746),
    LatLng(14.223416, 120.793316),
    LatLng(14.223434, 120.792689),
    LatLng(14.223337, 120.792115),
    LatLng(14.223189, 120.791791),
    LatLng(14.223136, 120.791402),
    LatLng(14.223227, 120.791099),
    LatLng(14.223709, 120.790971),
    LatLng(14.224990, 120.790794),
    LatLng(14.226515, 120.790112),
    LatLng(14.226728, 120.789962),
    LatLng(14.226873, 120.789677),
    LatLng(14.227102, 120.789517),
    LatLng(14.227369, 120.789426),
    LatLng(14.227670, 120.789493),
    LatLng(14.227971, 120.789620),
    LatLng(14.228364, 120.789732),
    LatLng(14.228953, 120.789731),
    LatLng(14.229259, 120.789623),
    LatLng(14.229697, 120.789341),
    LatLng(14.230001, 120.789010),
    LatLng(14.230151, 120.788477),
    LatLng(14.230250, 120.787844),
    LatLng(14.230467, 120.787385),
    LatLng(14.230691, 120.787028),
    LatLng(14.230978, 120.786753),
    LatLng(14.231203, 120.786571),
    LatLng(14.231420, 120.786317),
    LatLng(14.231758, 120.786093),
    LatLng(14.232190, 120.785834),
    LatLng(14.232690, 120.785730),
    LatLng(14.233018, 120.785770),
    LatLng(14.233325, 120.785884),
    LatLng(14.233489, 120.785941),
    LatLng(14.233706, 120.785952),
    LatLng(14.233924, 120.785910),
    LatLng(14.234214, 120.785714),
    LatLng(14.234319, 120.785554),
    LatLng(14.234369, 120.785337),
    LatLng(14.234424, 120.785151),
    LatLng(14.234440, 120.784900),
    LatLng(14.234531, 120.784764),
    LatLng(14.234636, 120.784712),
    LatLng(14.234872, 120.784719),
    LatLng(14.235056, 120.784760),
    LatLng(14.235262, 120.784705),
    LatLng(14.235384, 120.784532),
    LatLng(14.235498, 120.784302),
    LatLng(14.235514, 120.784038),
    LatLng(14.235683, 120.783774),
    LatLng(14.235856, 120.783599),
    LatLng(14.236114, 120.783541),
    LatLng(14.236368, 120.783573),
    LatLng(14.236585, 120.783650),
    LatLng(14.236813, 120.783699),
    LatLng(14.237031, 120.783693),
    LatLng(14.237245, 120.783651),
    LatLng(14.237391, 120.783704),
    LatLng(14.237536, 120.783710),
    LatLng(14.237711, 120.783608),
    LatLng(14.237799, 120.783463),
    LatLng(14.237910, 120.783339),
    LatLng(14.237965, 120.783144),
    LatLng(14.237962, 120.783034),
    LatLng(14.237978, 120.782883),
    LatLng(14.237992, 120.782774),
    LatLng(14.237832, 120.782761),
    LatLng(14.237650, 120.782721),
    LatLng(14.237305, 120.782599),
    LatLng(14.237056, 120.782540),
    LatLng(14.236837, 120.782505),
    LatLng(14.236752, 120.782437),
    LatLng(14.236698, 120.782322),
    LatLng(14.236488, 120.782083),
    LatLng(14.236334, 120.781974),
    LatLng(14.236167, 120.781889),
    LatLng(14.235820, 120.781771),
    LatLng(14.235474, 120.781604),
    LatLng(14.234985, 120.781380),
    LatLng(14.234726, 120.781374),
    LatLng(14.234466, 120.781400),
    LatLng(14.234053, 120.781394),
    LatLng(14.233592, 120.781432),
    LatLng(14.233236, 120.781456),
    LatLng(14.232870, 120.781503),
    LatLng(14.232725, 120.781477),
    LatLng(14.232394, 120.781171),
    LatLng(14.232186, 120.781038),
    LatLng(14.231942, 120.780937),
    LatLng(14.231735, 120.780768),
    LatLng(14.231625, 120.780541),
    LatLng(14.231369, 120.780443),
    LatLng(14.230950, 120.780143),
    LatLng(14.230861, 120.780126),
    LatLng(14.229726, 120.780760),
    LatLng(14.228701, 120.781457),
    LatLng(14.228161, 120.781754),
    LatLng(14.227759, 120.781847),
    LatLng(14.227229, 120.781776),
    LatLng(14.226530, 120.781431),
    LatLng(14.226128, 120.780586),
    LatLng(14.225895, 120.779919),
    LatLng(14.225738, 120.779670),
    LatLng(14.225502, 120.779551),
    LatLng(14.225058, 120.779469),
    LatLng(14.224466, 120.779474),
    LatLng(14.223554, 120.779441),
    LatLng(14.222861, 120.779421),
    LatLng(14.222132, 120.779306),
    LatLng(14.221312, 120.779342),
    LatLng(14.220627, 120.779418),
    LatLng(14.219996, 120.779570),
    LatLng(14.219215, 120.779820),
    LatLng(14.218899, 120.779874),
    LatLng(14.218582, 120.779887),
    LatLng(14.217633, 120.779758),
    LatLng(14.217327, 120.779624),
    LatLng(14.217064, 120.779374),
    LatLng(14.216783, 120.779180),
    LatLng(14.216679, 120.778978),
    LatLng(14.216661, 120.778817),
    LatLng(14.216749, 120.778626),
    LatLng(14.216796, 120.778521),
    LatLng(14.216815, 120.778374),
    LatLng(14.216708, 120.778174),
    LatLng(14.216578, 120.778035),
    LatLng(14.216480, 120.777887),
    LatLng(14.216437, 120.777669),
    LatLng(14.216282, 120.777509),
    LatLng(14.216113, 120.777486),
    LatLng(14.216010, 120.777471),
    LatLng(14.215688, 120.777471),
    LatLng(14.215431, 120.777143),
    LatLng(14.215343, 120.776791),
    LatLng(14.215344, 120.776599),
    LatLng(14.215372, 120.776450),
    LatLng(14.215536, 120.775970),
    LatLng(14.215650, 120.775808),
    LatLng(14.215758, 120.775603),
    LatLng(14.215834, 120.775324),
    LatLng(14.215874, 120.775076),
    LatLng(14.215888, 120.774841),
    LatLng(14.215907, 120.774622),
    LatLng(14.215877, 120.774463),
    LatLng(14.215724, 120.774287),
    LatLng(14.215568, 120.774122),
    LatLng(14.215313, 120.773982),
    LatLng(14.215128, 120.773832),
    LatLng(14.214751, 120.773673),
    LatLng(14.214388, 120.773575),
    LatLng(14.214113, 120.773781),
    LatLng(14.213832, 120.774156),
    LatLng(14.213676, 120.774335),
    LatLng(14.213536, 120.774407),
    LatLng(14.213335, 120.774578),
    LatLng(14.213128, 120.774663),
    LatLng(14.212925, 120.774689),
    LatLng(14.212713, 120.774743),
    LatLng(14.212490, 120.774706),
    LatLng(14.212293, 120.774707),
    LatLng(14.212113, 120.774689),
    LatLng(14.211942, 120.774587),
    LatLng(14.211661, 120.774470),
    LatLng(14.211362, 120.774483),
    LatLng(14.210990, 120.774398),
    LatLng(14.210864, 120.774314),
    LatLng(14.210629, 120.774352),
    LatLng(14.210439, 120.774231),
    LatLng(14.210033, 120.774311),
    LatLng(14.209735, 120.774298),
    LatLng(14.209192, 120.774434),
    LatLng(14.208827, 120.773940),
    LatLng(14.208353, 120.773501),
    LatLng(14.208111, 120.773052),
    LatLng(14.207927, 120.772785),
    LatLng(14.207819, 120.772479),
    LatLng(14.207719, 120.772196),
    LatLng(14.207525, 120.771942),
    LatLng(14.207419, 120.771849),
    LatLng(14.207225, 120.771704),
    LatLng(14.206707, 120.772108),
    LatLng(14.206429, 120.772363),
    LatLng(14.206217, 120.772705),
    LatLng(14.205983, 120.772883),
    LatLng(14.205796, 120.773149),
    LatLng(14.205540, 120.773276),
    LatLng(14.204987, 120.773566),
    LatLng(14.204733, 120.773572),
    LatLng(14.204480, 120.773726),
    LatLng(14.203963, 120.773686),
    LatLng(14.203730, 120.773570),
    LatLng(14.203405, 120.773494),
    LatLng(14.203203, 120.773369),
    LatLng(14.202730, 120.773354),
    LatLng(14.202562, 120.773268),
    LatLng(14.202385, 120.773269),
    LatLng(14.202183, 120.773443),
    LatLng(14.201983, 120.773682),
    LatLng(14.201698, 120.773883),
    LatLng(14.201323, 120.773897),
    LatLng(14.200713, 120.774038),
    LatLng(14.200377, 120.774012),
    LatLng(14.200072, 120.773878),
    LatLng(14.199814, 120.773646),
    LatLng(14.199664, 120.773495),
    LatLng(14.199382, 120.773394),
    LatLng(14.199062, 120.773331),
    LatLng(14.198856, 120.773345),
    LatLng(14.198606, 120.773319),
    LatLng(14.198395, 120.773385),
    LatLng(14.198159, 120.773549),
    LatLng(14.197855, 120.773890),
    LatLng(14.197442, 120.774193),
    LatLng(14.196996, 120.774303),
    LatLng(14.196607, 120.774371),
    LatLng(14.196291, 120.774368),
    LatLng(14.195964, 120.774405),
    LatLng(14.195637, 120.774324),
    LatLng(14.195275, 120.774222),
    LatLng(14.194922, 120.774203),
    LatLng(14.194604, 120.774267),
    LatLng(14.194267, 120.774180),
    LatLng(14.193849, 120.773979),
    LatLng(14.193485, 120.773933),
    LatLng(14.193074, 120.774066),
    LatLng(14.192858, 120.774334),
    LatLng(14.192577, 120.774591),
    LatLng(14.192291, 120.774627),
    LatLng(14.191682, 120.774758),
    LatLng(14.191419, 120.774777),
    LatLng(14.191282, 120.774878),
    LatLng(14.191195, 120.775082),
    LatLng(14.191177, 120.775387),
    LatLng(14.191241, 120.775619),
    LatLng(14.191298, 120.775844),
    LatLng(14.191272, 120.776158),
    LatLng(14.191081, 120.776411),
    LatLng(14.190903, 120.776604),
    LatLng(14.190660, 120.776679),
    LatLng(14.190295, 120.776670),
    LatLng(14.189919, 120.776724),
    LatLng(14.189457, 120.776668),
    LatLng(14.189055, 120.776621),
    LatLng(14.188690, 120.776602),
    LatLng(14.188361, 120.776442),
    LatLng(14.187959, 120.776337),
    LatLng(14.187661, 120.776296),
    LatLng(14.187169, 120.776358),
    LatLng(14.186748, 120.776505),
    LatLng(14.186099, 120.776928),
    LatLng(14.185599, 120.777254),
    LatLng(14.185246, 120.777494),
    LatLng(14.185039, 120.777679),
    LatLng(14.184904, 120.777698),
    LatLng(14.184762, 120.777621),
    LatLng(14.184551, 120.777512),
    LatLng(14.184260, 120.777529),
    LatLng(14.183884, 120.777781),
    LatLng(14.183665, 120.777915),
    LatLng(14.183568, 120.778199),
    LatLng(14.183461, 120.778300),
    LatLng(14.183204, 120.778234),
    LatLng(14.182878, 120.778113),
    LatLng(14.182673, 120.778125),
    LatLng(14.182443, 120.778281),
    LatLng(14.182277, 120.778367),
    LatLng(14.182117, 120.778392),
    LatLng(14.181886, 120.778471),
    LatLng(14.181452, 120.778616),
    LatLng(14.181192, 120.778780),
    LatLng(14.180889, 120.778886),
    LatLng(14.180429, 120.778783),
    LatLng(14.180328, 120.778744),
    LatLng(14.180151, 120.778777),
    LatLng(14.179945, 120.778692),
    LatLng(14.179749, 120.778521),
    LatLng(14.179552, 120.778329),
    LatLng(14.179327, 120.778285),
    LatLng(14.179105, 120.778351),
    LatLng(14.178845, 120.778365),
    LatLng(14.178600, 120.778312),
    LatLng(14.178275, 120.778377),
    LatLng(14.177896, 120.778321),
    LatLng(14.177008, 120.778402),
    LatLng(14.176361, 120.778796),
    LatLng(14.175774, 120.779153),
    LatLng(14.175159, 120.779462),
    LatLng(14.174784, 120.779644),
    LatLng(14.174627, 120.779502),
    LatLng(14.174537, 120.779374),
    LatLng(14.174371, 120.779192),
    LatLng(14.174155, 120.779100),
    LatLng(14.173736, 120.779064),
    LatLng(14.173323, 120.778977),
    LatLng(14.173082, 120.778810),
    LatLng(14.172869, 120.778769),
    LatLng(14.172600, 120.778848),
    LatLng(14.172280, 120.778994),
    LatLng(14.171841, 120.779120),
    LatLng(14.171380, 120.779149),
    LatLng(14.171191, 120.779193),
    LatLng(14.171048, 120.779284),
    LatLng(14.170897, 120.779446),
    LatLng(14.170901, 120.779641),
    LatLng(14.170975, 120.779771),
    LatLng(14.171048, 120.779900),
    LatLng(14.171046, 120.780195),
    LatLng(14.171011, 120.780507),
    LatLng(14.170945, 120.780760),
    LatLng(14.170957, 120.780971),
    LatLng(14.170932, 120.781265),
    LatLng(14.170997, 120.781428),
    LatLng(14.170962, 120.781740),
    LatLng(14.170794, 120.782115),
    LatLng(14.170509, 120.782267),
    LatLng(14.170160, 120.782480),
    LatLng(14.169796, 120.782617),
    LatLng(14.169164, 120.782835),
    LatLng(14.168737, 120.782902),
    LatLng(14.168517, 120.783036),
    LatLng(14.168337, 120.783270),
    LatLng(14.168097, 120.783405),
    LatLng(14.167771, 120.783372),
    LatLng(14.167531, 120.783394),
    LatLng(14.167114, 120.783595),
    LatLng(14.166697, 120.783717),
    LatLng(14.166536, 120.783998),
    LatLng(14.166244, 120.784220),
    LatLng(14.165847, 120.784155),
    LatLng(14.165545, 120.784206),
    LatLng(14.165098, 120.784063),
    LatLng(14.164734, 120.784148),
    LatLng(14.164267, 120.784243),
    LatLng(14.163874, 120.784243),
    LatLng(14.163640, 120.784090),
    LatLng(14.163387, 120.784006),
    LatLng(14.162955, 120.783982),
    LatLng(14.162600, 120.783971),
    LatLng(14.162283, 120.784006),
    LatLng(14.162025, 120.784102),
    LatLng(14.161654, 120.784124),
    LatLng(14.161370, 120.783999),
    LatLng(14.161214, 120.784177),
    LatLng(14.161086, 120.784418),
    LatLng(14.160436, 120.784869),
    LatLng(14.160239, 120.785076),
    LatLng(14.159952, 120.785171),
    LatLng(14.159635, 120.785505),
    LatLng(14.159389, 120.785430),
    LatLng(14.159332, 120.785382),
    LatLng(14.159057, 120.785092),
    LatLng(14.158924, 120.785089),
    LatLng(14.158909, 120.785364),
    LatLng(14.158752, 120.785589),
    LatLng(14.158494, 120.785775),
    LatLng(14.158237, 120.785737),
    LatLng(14.158023, 120.785926),
    LatLng(14.157852, 120.786157),
    LatLng(14.157861, 120.786535),
    LatLng(14.157813, 120.786952),
    LatLng(14.157597, 120.787512),
    LatLng(14.157177, 120.787535),
    LatLng(14.156973, 120.787833),
    LatLng(14.156637, 120.788004),
    LatLng(14.156304, 120.788301),
    LatLng(14.155839, 120.788703),
    LatLng(14.155722, 120.789034),
    LatLng(14.155413, 120.789220),
    LatLng(14.155135, 120.789194),
    LatLng(14.154997, 120.789271),
    LatLng(14.155026, 120.789528),
    LatLng(14.155055, 120.789785),
    LatLng(14.154832, 120.790163),
    LatLng(14.154754, 120.790347),
    LatLng(14.154569, 120.790464),
    LatLng(14.154053, 120.790466),
    LatLng(14.153770, 120.790583),
    LatLng(14.153524, 120.790672),
    LatLng(14.153174, 120.790691),
    LatLng(14.152841, 120.790794),
    LatLng(14.152392, 120.790758),
    LatLng(14.151879, 120.790634),
    LatLng(14.151497, 120.790620),
    LatLng(14.151010, 120.790750),
    LatLng(14.150659, 120.791073),
    LatLng(14.150349, 120.791227),
    LatLng(14.149872, 120.791193),
    LatLng(14.149412, 120.791278),
    LatLng(14.149145, 120.791746),
    LatLng(14.148721, 120.792054),
    LatLng(14.148134, 120.792268),
    LatLng(14.147648, 120.792334),
    LatLng(14.147472, 120.792385),
    LatLng(14.146907, 120.792550),
    LatLng(14.146663, 120.792740),
    LatLng(14.146476, 120.793034),
    LatLng(14.146320, 120.793651),
    LatLng(14.146229, 120.794395),
    LatLng(14.146176, 120.794741),
    LatLng(14.146081, 120.794955),
    LatLng(14.145731, 120.795151),
    LatLng(14.145452, 120.795451),
    LatLng(14.145174, 120.795392),
    LatLng(14.144967, 120.795274),
    LatLng(14.144850, 120.795346),
    LatLng(14.144782, 120.795463),
    LatLng(14.144693, 120.795624),
    LatLng(14.144659, 120.795840),
    LatLng(14.144453, 120.795924),
    LatLng(14.144247, 120.795940),
    LatLng(14.143779, 120.796191),
    LatLng(14.143287, 120.796368),
    LatLng(14.142988, 120.796814),
    LatLng(14.142617, 120.797314),
    LatLng(14.142490, 120.797758),
    LatLng(14.142320, 120.798180),
    LatLng(14.141865, 120.798343),
    LatLng(14.141895, 120.798619),
    LatLng(14.142143, 120.798974),
    LatLng(14.142298, 120.799188),
    LatLng(14.142313, 120.799457),
    LatLng(14.142340, 120.799674),
    LatLng(14.142258, 120.799812),
    LatLng(14.141971, 120.800127),
    LatLng(14.141937, 120.800467),
    LatLng(14.141817, 120.801055),
    LatLng(14.141635, 120.801541),
    LatLng(14.141427, 120.801843),
    LatLng(14.141059, 120.802197),
    LatLng(14.140776, 120.802181),
    LatLng(14.140161, 120.802003),
    LatLng(14.139356, 120.802021),
    LatLng(14.139231, 120.802427),
    LatLng(14.138617, 120.802614),
    LatLng(14.138201, 120.802410),
    LatLng(14.137781, 120.802321),
    LatLng(14.137434, 120.802789),
    LatLng(14.136824, 120.802854),
    LatLng(14.136754, 120.803759),
    LatLng(14.136646, 120.804147),
    LatLng(14.136366, 120.804519),
    LatLng(14.136126, 120.804743),
    LatLng(14.135878, 120.804866),
    LatLng(14.135532, 120.804848),
    LatLng(14.135386, 120.804958),
    LatLng(14.135305, 120.805128),
    LatLng(14.135171, 120.805574),
    LatLng(14.135058, 120.805621),
    LatLng(14.134912, 120.805574),
    LatLng(14.134494, 120.805334),
    LatLng(14.134227, 120.805277),
    LatLng(14.134034, 120.805407),
    LatLng(14.133992, 120.805633),
    LatLng(14.134023, 120.805909),
    LatLng(14.133883, 120.806226),
    LatLng(14.133643, 120.806417),
    LatLng(14.133399, 120.806573),
    LatLng(14.133047, 120.806627),
    LatLng(14.132456, 120.807310),
    LatLng(14.132394, 120.807649),
    LatLng(14.132408, 120.808173),
    LatLng(14.132257, 120.808364),
    LatLng(14.132105, 120.808554),
    LatLng(14.131689, 120.808931),
    LatLng(14.131441, 120.808985),
    LatLng(14.131602, 120.809359),
    LatLng(14.131820, 120.809813),
    LatLng(14.132020, 120.810360),
    LatLng(14.131988, 120.810556),
    LatLng(14.132017, 120.810806),
    LatLng(14.132104, 120.811126),
    LatLng(14.132261, 120.811455),
    LatLng(14.132327, 120.811587),
    LatLng(14.132376, 120.811732),
    LatLng(14.132529, 120.811950),
    LatLng(14.132649, 120.812214),
    LatLng(14.132769, 120.812552),
    LatLng(14.132919, 120.812879),
    LatLng(14.133112, 120.813338),
    LatLng(14.133539, 120.814088),
    LatLng(14.133694, 120.814027),
    LatLng(14.133963, 120.813901),
    LatLng(14.134132, 120.813770),
    LatLng(14.134253, 120.813729),
    LatLng(14.134343, 120.813958),
    LatLng(14.134412, 120.814283),
    LatLng(14.134595, 120.814709),
    LatLng(14.134695, 120.814912),
    LatLng(14.134882, 120.815171),
    LatLng(14.134956, 120.815365),
    LatLng(14.135054, 120.815508),
    LatLng(14.135125, 120.815772),
    LatLng(14.135257, 120.815927),
    LatLng(14.135340, 120.816090),
    LatLng(14.135512, 120.816319),
    LatLng(14.135733, 120.816620),
    LatLng(14.135831, 120.816829),
    LatLng(14.135894, 120.817131),
    LatLng(14.135970, 120.817357),
    LatLng(14.136035, 120.817552),
    LatLng(14.136083, 120.817774),
    LatLng(14.136117, 120.817977),
    LatLng(14.136219, 120.818153),
    LatLng(14.136313, 120.818417),
    LatLng(14.136393, 120.818745),
    LatLng(14.136508, 120.818966),
    LatLng(14.136646, 120.819397),
    LatLng(14.136851, 120.819939),
    LatLng(14.137006, 120.820279),
    LatLng(14.137248, 120.820533),
    LatLng(14.137456, 120.820569),
    LatLng(14.137619, 120.820604),
    LatLng(14.137877, 120.821061),
    LatLng(14.138088, 120.821385),
    LatLng(14.138299, 120.821765),
    LatLng(14.138466, 120.822289),
    LatLng(14.138618, 120.823049),
    LatLng(14.138659, 120.823484),
    LatLng(14.138796, 120.823936),
    LatLng(14.138953, 120.824316),
    LatLng(14.139055, 120.824802),
    LatLng(14.139315, 120.825431),
    LatLng(14.139597, 120.825908),
    LatLng(14.139973, 120.826425),
    LatLng(14.140144, 120.826785),
    LatLng(14.140379, 120.827181),
    LatLng(14.140575, 120.827577),
    LatLng(14.140772, 120.828073),
    LatLng(14.140984, 120.828724),
    LatLng(14.141196, 120.829099),
    LatLng(14.141671, 120.828875),
    LatLng(14.142038, 120.829656),
    LatLng(14.142273, 120.830146),
    LatLng(14.142587, 120.830645),
    LatLng(14.143140, 120.831792),
    LatLng(14.143582, 120.832415),
    LatLng(14.143750, 120.832783),
    LatLng(14.144045, 120.833122),
    LatLng(14.144311, 120.833716),
    LatLng(14.144550, 120.834424),
    LatLng(14.144969, 120.835297),
    LatLng(14.145251, 120.835754),
    LatLng(14.145532, 120.836276),
    LatLng(14.146119, 120.836614),
    LatLng(14.146052, 120.836777),
    LatLng(14.146463, 120.838110),
    LatLng(14.146957, 120.839103),
    LatLng(14.146992, 120.839175),
    LatLng(14.147111, 120.839175),
    LatLng(14.147217, 120.839144),
    LatLng(14.147345, 120.839085),
    LatLng(14.147482, 120.838888),
    LatLng(14.147622, 120.838872),
    LatLng(14.147758, 120.838895),
    LatLng(14.148031, 120.838793),
    LatLng(14.148276, 120.838669),
    LatLng(14.148445, 120.838529),
    LatLng(14.148612, 120.838320),
    LatLng(14.148739, 120.838139),
    LatLng(14.148980, 120.838087),
    LatLng(14.149298, 120.838205),
    LatLng(14.149595, 120.838208),
    LatLng(14.150024, 120.838141),
    LatLng(14.150298, 120.838182),
    LatLng(14.150443, 120.838366),
    LatLng(14.150659, 120.838338),
    LatLng(14.150876, 120.838309),
    LatLng(14.151046, 120.838256),
    LatLng(14.151103, 120.838127),
    LatLng(14.151251, 120.838091),
    LatLng(14.151611, 120.838089),
    LatLng(14.151866, 120.838209),
    LatLng(14.151898, 120.838398),
    LatLng(14.152145, 120.838415),
    LatLng(14.152330, 120.838373),
    LatLng(14.152465, 120.838246),
    LatLng(14.152574, 120.838270),
    LatLng(14.152593, 120.838412),
    LatLng(14.152671, 120.838517),
    LatLng(14.152762, 120.838478),
    LatLng(14.152892, 120.838345),
    LatLng(14.153078, 120.838275),
    LatLng(14.153232, 120.838143),
    LatLng(14.153365, 120.838131),
    LatLng(14.153513, 120.838183),
    LatLng(14.153728, 120.837968),
    LatLng(14.153951, 120.837881),
    LatLng(14.154153, 120.837642),
    LatLng(14.154117, 120.837401),
    LatLng(14.154266, 120.837261),
    LatLng(14.154401, 120.837195),
    LatLng(14.154550, 120.837208),
    LatLng(14.154728, 120.837140),
    LatLng(14.154844, 120.837032),
    LatLng(14.154860, 120.836909),
    LatLng(14.154909, 120.836871),
    LatLng(14.155030, 120.836862),
    LatLng(14.155315, 120.836841),
    LatLng(14.155497, 120.836775),
    LatLng(14.155765, 120.836720),
    LatLng(14.155944, 120.836502),
    LatLng(14.156112, 120.836529),
    LatLng(14.156171, 120.836343),
    LatLng(14.156494, 120.836247),
    LatLng(14.156872, 120.836161),
    LatLng(14.157133, 120.836180),
    LatLng(14.157422, 120.836106),
    LatLng(14.157646, 120.835973),
    LatLng(14.157923, 120.835910),
    LatLng(14.158124, 120.835652),
    LatLng(14.158303, 120.835572),
    LatLng(14.158514, 120.835615),
    LatLng(14.158709, 120.835588),
    LatLng(14.158821, 120.835468),
    LatLng(14.159084, 120.835479),
    LatLng(14.159356, 120.835330),
    LatLng(14.159458, 120.835048),
    LatLng(14.159611, 120.834966),
    LatLng(14.159753, 120.834750),
    LatLng(14.159980, 120.834922),
    LatLng(14.160319, 120.834791),
    LatLng(14.160412, 120.834739),
    LatLng(14.160687, 120.834702),
    LatLng(14.160929, 120.834388),
    LatLng(14.161021, 120.834326),
    LatLng(14.161201, 120.834445),
    LatLng(14.161243, 120.834610),
    LatLng(14.161361, 120.834575),
    LatLng(14.161864, 120.834547),
    LatLng(14.161986, 120.834547),
    LatLng(14.162324, 120.834423),
    LatLng(14.162937, 120.834323),
    LatLng(14.163381, 120.834129),
    LatLng(14.163876, 120.833681),
    LatLng(14.164123, 120.833251),
    LatLng(14.164537, 120.832895),
    LatLng(14.164884, 120.832693),
    LatLng(14.165311, 120.832480),
    LatLng(14.165593, 120.832174),
    LatLng(14.165861, 120.832141),
    LatLng(14.166102, 120.831977),
    LatLng(14.166258, 120.831742),
    LatLng(14.166536, 120.831522),
    LatLng(14.166769, 120.831513),
    LatLng(14.167039, 120.831205),
    LatLng(14.167115, 120.831033),
    LatLng(14.167244, 120.831077),
    LatLng(14.167454, 120.830888),
    LatLng(14.167488, 120.830656),
    LatLng(14.167599, 120.830381),
    LatLng(14.167777, 120.830229),
    LatLng(14.167948, 120.830247),
    LatLng(14.168449, 120.829905),
    LatLng(14.168694, 120.829683),
    LatLng(14.168676, 120.829386),
    LatLng(14.168801, 120.829141),
    LatLng(14.168967, 120.829089),
    LatLng(14.169088, 120.829187),
    LatLng(14.169308, 120.828998),
    LatLng(14.169383, 120.828641),
    LatLng(14.169549, 120.828433),
    LatLng(14.169733, 120.828472),
    LatLng(14.170074, 120.828408),
    LatLng(14.170326, 120.828492),
    LatLng(14.170525, 120.828303),
    LatLng(14.170814, 120.828148),
    LatLng(14.170972, 120.828159),
    LatLng(14.171076, 120.828226),
    LatLng(14.171236, 120.828247),
    LatLng(14.171404, 120.828183),
    LatLng(14.171506, 120.827971),
    LatLng(14.171600, 120.827735),
    LatLng(14.171838, 120.827645),
    LatLng(14.172074, 120.827656),
    LatLng(14.172325, 120.827643),
    LatLng(14.172407, 120.827186),
    LatLng(14.172532, 120.826954),
    LatLng(14.172802, 120.826881),
    LatLng(14.173010, 120.826904),
    LatLng(14.173309, 120.826935),
    LatLng(14.173583, 120.827133),
    LatLng(14.173705, 120.827355),
    LatLng(14.173921, 120.827439),
    LatLng(14.174321, 120.827304),
    LatLng(14.174544, 120.827036),
    LatLng(14.174663, 120.826628),
    LatLng(14.174856, 120.826288),
    LatLng(14.174933, 120.826077),
    LatLng(14.174990, 120.825696),
    LatLng(14.174933, 120.825556),
    LatLng(14.174824, 120.825523),
    LatLng(14.174738, 120.825340),
    LatLng(14.174864, 120.825160),
    LatLng(14.175140, 120.825028),
    LatLng(14.175406, 120.824975),
    LatLng(14.175684, 120.824559),
    LatLng(14.175858, 120.824282),
    LatLng(14.176143, 120.824078),
    LatLng(14.176336, 120.823962),
    LatLng(14.176539, 120.823903),
    LatLng(14.176654, 120.823737),
    LatLng(14.176819, 120.823553),
    LatLng(14.177138, 120.823308),
    LatLng(14.177494, 120.823329),
    LatLng(14.177775, 120.823183),
    LatLng(14.177993, 120.822915),
    LatLng(14.178355, 120.822773),
    LatLng(14.178826, 120.822693),
    LatLng(14.179289, 120.822529),
    LatLng(14.179645, 120.822372),
    LatLng(14.179758, 120.822081),
    LatLng(14.179897, 120.821856),
    LatLng(14.180329, 120.821837),
    LatLng(14.180699, 120.821949),
    LatLng(14.181150, 120.821901),
    LatLng(14.181513, 120.821798),
    LatLng(14.181681, 120.821513),
    LatLng(14.181740, 120.821272),
    LatLng(14.181960, 120.821296),
    LatLng(14.182198, 120.821198),
    LatLng(14.182429, 120.821003),
    LatLng(14.182721, 120.820980),
    LatLng(14.182968, 120.821097),
    LatLng(14.183351, 120.821304),
    LatLng(14.183532, 120.821550),
  ];

  LatLng _pickedLocation = _municipalCenter;
  LatLng? _currentLocation;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  bool _isReverseGeocoding = false;
  String _streetAddress = '';
  List<Map<String, dynamic>> _searchResults = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _reverseGeocode(_municipalCenter);
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) return;

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
    } catch (_) {}
  }

  LatLng _clampToBounds(LatLng point) {
    final lat = point.latitude.clamp(
      _municipalBounds.south,
      _municipalBounds.north,
    );
    final lon = point.longitude.clamp(
      _municipalBounds.west,
      _municipalBounds.east,
    );
    return LatLng(lat, lon);
  }

  bool _isInsideBounds(LatLng point) {
    return _municipalBounds.contains(point);
  }

  Future<void> _reverseGeocode(LatLng point) async {
    setState(() {
      _isReverseGeocoding = true;
      _streetAddress = '';
    });

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${point.latitude}&lon=${point.longitude}'
        '&format=json&addressdetails=1',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'com.example.bfp_final'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final road = address['road'] as String?;
          final neighbourhood = address['neighbourhood'] as String?;
          final village = address['village'] as String?;
          final suburb = address['suburb'] as String?;
          final city = address['city'] as String?
              ?? address['town'] as String?
              ?? address['municipality'] as String?;

          final parts = [
            road ?? neighbourhood,
            suburb ?? village,
            city,
          ].whereType<String>().toList();

          setState(() {
            _streetAddress = parts.isNotEmpty
                ? parts.join(', ')
                : (data['display_name'] as String? ?? '');
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _streetAddress = 'Unable to fetch address');
    } finally {
      if (mounted) setState(() => _isReverseGeocoding = false);
    }
  }

  Future<void> _searchLocation(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _showResults = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&limit=5&addressdetails=1'
        '&viewbox=${_municipalBounds.west},${_municipalBounds.north},'
        '${_municipalBounds.east},${_municipalBounds.south}'
        '&bounded=1',
      );

      final response = await http.get(
        uri,
        headers: {'User-Agent': 'com.example.bfp_final'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List results = json.decode(response.body);
        setState(() {
          _searchResults = results
              .map((r) => {
                    'display_name': r['display_name'] as String,
                    'lat': double.parse(r['lat']),
                    'lon': double.parse(r['lon']),
                  })
              .toList();
          _showResults = _searchResults.isNotEmpty;
        });

        if (_searchResults.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No results found within the area.')),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Search failed. Check your connection.')),
      );
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectResult(Map<String, dynamic> result) {
    final location = LatLng(result['lat'], result['lon']);
    final clamped = _clampToBounds(location);
    setState(() {
      _pickedLocation = clamped;
      _showResults = false;
      _searchController.text = result['display_name'];
    });
    _mapController.move(clamped, 17.0);
    FocusScope.of(context).unfocus();
    _reverseGeocode(clamped);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _showResults = false;
    });
    FocusScope.of(context).unfocus();
  }

  Widget _buildSearchResults() {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 280),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.place, size: 14, color: Colors.grey.shade500),
                  const SizedBox(width: 6),
                  Text(
                    '${_searchResults.length} result${_searchResults.length > 1 ? 's' : ''} found',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade500,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearSearch,
                    child: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),

            // Results list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  final parts = (result['display_name'] as String).split(', ');
                  final title = parts.first;
                  final subtitle =
                      parts.length > 1 ? parts.skip(1).join(', ') : '';

                  return InkWell(
                    onTap: () => _selectResult(result),
                    splashColor: Colors.red.withValues(alpha: 0.06),
                    highlightColor: Colors.red.withValues(alpha: 0.03),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: index < _searchResults.length - 1
                            ? Border(
                                bottom: BorderSide(color: Colors.grey.shade100),
                              )
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on,
                              color: Colors.redAccent,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtitle.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2, left: 8),
                            child: Icon(
                              Icons.arrow_forward_ios,
                              size: 11,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gen. E. Aguinaldo / Bailen'),
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _municipalCenter,
              initialZoom: 15.5,
              minZoom: 14.5,
              maxZoom: 19.0,
              cameraConstraint: CameraConstraint.containCenter(
                bounds: _municipalBounds,
              ),
              onTap: (tapPosition, point) {
                if (_isInsideBounds(point)) {
                  setState(() {
                    _pickedLocation = point;
                    _showResults = false;
                  });
                  FocusScope.of(context).unfocus();
                  _reverseGeocode(point);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please pick a location within the municipality.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.bfp_final',
              ),
              PolygonLayer(
                polygons: [
                  Polygon(
                    points: _municipalPolygon,
                    color: Colors.blue.withValues(alpha: 0.08),
                    borderColor: Colors.blue.withValues(alpha: 0.6),
                    borderStrokeWidth: 2.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Current location — blue dot
                  if (_currentLocation != null)
                    Marker(
                      point: _currentLocation!,
                      width: 36,
                      height: 36,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withValues(alpha: 0.15),
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.blue.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.circle,
                          color: Colors.blue,
                          size: 16,
                        ),
                      ),
                    ),

                  // Picked location — red pin
                  Marker(
                    point: _pickedLocation,
                    width: 50,
                    height: 50,
                    child: const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 50,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // ── Search bar + dropdown ─────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(color: Colors.black),
                    decoration: InputDecoration(
                      hintText: 'Search location',
                      hintStyle: const TextStyle(color: Colors.black54),
                      prefixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearSearch,
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    onChanged: (value) {
                      Future.delayed(const Duration(milliseconds: 500), () {
                        if (value == _searchController.text) {
                          _searchLocation(value);
                        }
                      });
                    },
                    onSubmitted: _searchLocation,
                    textInputAction: TextInputAction.search,
                  ),
                ),
                if (_showResults) _buildSearchResults(),
              ],
            ),
          ),

          // ── Address + Confirm card ────────────────────────────
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Street address row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _isReverseGeocoding
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _streetAddress.isNotEmpty
                                      ? _streetAddress
                                      : 'Tap the map to pick a location',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Confirm button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Confirm Location'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _isReverseGeocoding
                          ? null
                          : () => Navigator.pop<Map<String, dynamic>>(context, {
                                'location': _pickedLocation,
                                'address': _streetAddress,
                              }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}