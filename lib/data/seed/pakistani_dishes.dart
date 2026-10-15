import 'package:aaj_kya_pakayen/domain/entities/dish.dart';
import 'package:aaj_kya_pakayen/domain/entities/dish_pairing.dart';
import 'package:aaj_kya_pakayen/domain/enums/cooking_style.dart';
import 'package:aaj_kya_pakayen/domain/enums/dish_type.dart';
import 'package:aaj_kya_pakayen/domain/enums/staple_pairing.dart';

export 'package:aaj_kya_pakayen/domain/entities/dish.dart'
    show firstCustomDishId;

// Built-in Pakistani dishes. Ids are stable forever: history rows point at
// them. Ranges: 1–29 vegetable, 30–49 pulse, 50–69 chicken, 70–79 beef,
// 80–89 mutton, 90–99 mince. Custom dishes start at [firstCustomDishId].
//
// protein_grams_per_person is raw meat per adult serving (bone-in for karahi
// and qorma; less for dishes bulked out with potatoes, peas or daal).

/// Bump when the seed list changes so existing installs pick it up.
const seedVersion = 1;

Dish _veg(
  int id,
  String en,
  String ur,
  CookingStyle style,
  int minutes, {
  bool side = true,
  StaplePairing staple = StaplePairing.roti,
  String? group,
}) => Dish(
  id: id,
  nameEn: en,
  nameUr: ur,
  dishType: DishType.vegetable,
  staplePairing: staple,
  cookingStyle: style,
  prepMinutes: minutes,
  canBeSide: side,
  variantGroup: group,
);

Dish _pulse(
  int id,
  String en,
  String ur,
  StaplePairing staple,
  int minutes, {
  CookingStyle style = CookingStyle.curry,
  String? group,
}) => Dish(
  id: id,
  nameEn: en,
  nameUr: ur,
  dishType: DishType.pulse,
  staplePairing: staple,
  cookingStyle: style,
  prepMinutes: minutes,
  variantGroup: group,
);

Dish _meat(
  int id,
  DishType type,
  String en,
  String ur,
  int grams,
  CookingStyle style,
  StaplePairing staple,
  int minutes, {
  String? group,
}) => Dish(
  id: id,
  nameEn: en,
  nameUr: ur,
  dishType: type,
  proteinGramsPerPerson: grams,
  staplePairing: staple,
  cookingStyle: style,
  prepMinutes: minutes,
  variantGroup: group,
);

const DishType _c = DishType.chicken;
const DishType _b = DishType.beef;
const DishType _m = DishType.mutton;
const DishType _q = DishType.mince;

const StaplePairing _rice = StaplePairing.rice;
const StaplePairing _roti = StaplePairing.roti;
const StaplePairing _either = StaplePairing.either;
const StaplePairing _none = StaplePairing.none;

const CookingStyle _karahi = CookingStyle.karahi;
const CookingStyle _curry = CookingStyle.curry;
const CookingStyle _bbq = CookingStyle.bbq;
const CookingStyle _roast = CookingStyle.roast;
const CookingStyle _fry = CookingStyle.fry;
const CookingStyle _stew = CookingStyle.stew;
const CookingStyle _riceDish = CookingStyle.riceDish;

final List<Dish> pakistaniDishes = List.unmodifiable(<Dish>[
  // Vegetable
  _veg(1, 'Aloo Gobi', 'آلو گوبھی', _curry, 35),
  _veg(2, 'Bhindi Masala', 'بھنڈی مسالا', _fry, 30),
  _veg(3, 'Baingan Bharta', 'بینگن کا بھرتا', _roast, 40),
  _veg(4, 'Aloo Matar', 'آلو مٹر', _curry, 30),
  _veg(5, 'Karela Masala', 'مسالے دار کریلے', _fry, 50),
  _veg(6, 'Tinda', 'ٹینڈے', _curry, 35),
  _veg(7, 'Lauki', 'لوکی', _curry, 35),
  _veg(8, 'Palak Paneer', 'پالک پنیر', _curry, 40),
  _veg(9, 'Mixed Sabzi', 'مکس سبزی', _curry, 35),
  _veg(10, 'Khatta Meetha Kaddu', 'کھٹا میٹھا کدو', _curry, 35),
  _veg(11, 'Turai', 'توری', _curry, 30),
  _veg(12, 'Arvi', 'اروی', _fry, 40),
  _veg(13, 'Shalgam', 'شلجم', _curry, 40),
  _veg(
    14,
    'Matar Pulao',
    'مٹر پلاؤ',
    _riceDish,
    45,
    side: false,
    staple: _none,
  ),
  _veg(15, 'Aloo Palak', 'آلو پالک', _curry, 35),
  _veg(16, 'Gobi Masala', 'گوبھی مسالا', _fry, 30),
  _veg(17, 'Aloo Baingan', 'آلو بینگن', _curry, 35),
  _veg(18, 'Sarson ka Saag', 'سرسوں کا ساگ', _stew, 120, side: false),
  _veg(19, 'Shimla Mirch Aloo', 'شملہ مرچ آلو', _fry, 25),
  _veg(20, 'Aloo ki Bhujia', 'آلو کی بھجیا', _fry, 20),
  _veg(21, 'Aloo Tamatar', 'آلو ٹماٹر', _curry, 25),
  _veg(
    22,
    'Sabzi Biryani',
    'سبزی بریانی',
    _riceDish,
    60,
    side: false,
    staple: _none,
  ),
  _veg(23, 'Aloo Methi', 'آلو میتھی', _fry, 30),

  // Pulses and grams
  _pulse(30, 'Daal Chawal', 'دال چاول', _rice, 40),
  _pulse(31, 'Mash ki Daal', 'ماش کی دال', _roti, 45, group: 'mash_daal'),
  _pulse(
    32,
    'Daal Mash Tarka',
    'دال ماش تڑکا',
    _roti,
    40,
    style: _fry,
    group: 'mash_daal',
  ),
  _pulse(33, 'Masoor Daal', 'مسور کی دال', _rice, 35),
  _pulse(34, 'Moong Daal', 'مونگ کی دال', _either, 30),
  _pulse(35, 'Chana Daal', 'چنے کی دال', _either, 50),
  _pulse(36, 'Khichdi', 'کھچڑی', _rice, 40, style: _riceDish),
  _pulse(37, 'Rajma Chawal', 'راجما چاول', _rice, 60),
  _pulse(38, 'Lobia Chawal', 'لوبیا چاول', _rice, 50, group: 'lobia'),
  _pulse(39, 'Chana Pulao', 'چنا پلاؤ', _rice, 60, style: _riceDish),
  _pulse(40, 'Kala Chana', 'کالے چنے', _either, 60),
  _pulse(41, 'Cholay', 'چھولے', _either, 45),
  _pulse(42, 'Kadhi Chawal', 'کڑھی چاول', _rice, 60),
  _pulse(43, 'Daal Palak', 'دال پالک', _either, 40),
  _pulse(44, 'Daal Makhni', 'دال مکھنی', _either, 90),
  _pulse(45, 'Lobia Masala', 'لوبیا مسالا', _roti, 50, group: 'lobia'),

  // Chicken
  _meat(
    50,
    _c,
    'Chicken Karahi',
    'چکن کڑاہی',
    200,
    _karahi,
    _roti,
    45,
    group: 'chicken_karahi',
  ),
  _meat(
    51,
    _c,
    'Chicken White Karahi',
    'چکن وائٹ کڑاہی',
    200,
    _karahi,
    _roti,
    45,
    group: 'chicken_karahi',
  ),
  _meat(52, _c, 'Chicken Handi', 'چکن ہانڈی', 200, _curry, _roti, 45),
  _meat(53, _c, 'Chicken Qorma', 'چکن قورمہ', 200, _curry, _roti, 60),
  _meat(54, _c, 'Chicken Biryani', 'چکن بریانی', 175, _riceDish, _none, 75),
  _meat(55, _c, 'Chicken Pulao', 'چکن پلاؤ', 175, _riceDish, _none, 60),
  _meat(56, _c, 'Chicken Jalfrezi', 'چکن جلفریزی', 175, _fry, _roti, 35),
  _meat(57, _c, 'Butter Chicken', 'بٹر چکن', 175, _curry, _either, 50),
  _meat(58, _c, 'Chicken Tikka', 'چکن تکہ', 250, _bbq, _roti, 60),
  _meat(59, _c, 'Achari Chicken', 'اچاری چکن', 200, _curry, _roti, 45),
  _meat(
    60,
    _c,
    'Aloo Chicken Salan',
    'آلو چکن کا سالن',
    150,
    _curry,
    _either,
    45,
  ),
  _meat(61, _c, 'Chicken Shashlik', 'چکن شاشلک', 150, _fry, _rice, 40),
  _meat(
    62,
    _c,
    'Chicken Steam Roast',
    'چکن اسٹیم روسٹ',
    250,
    _roast,
    _none,
    60,
  ),
  _meat(63, _c, 'Chicken Malai Boti', 'چکن ملائی بوٹی', 200, _bbq, _roti, 50),

  // Beef
  _meat(70, _b, 'Beef Nihari', 'بیف نہاری', 200, _stew, _roti, 240),
  _meat(71, _b, 'Beef Karahi', 'بیف کڑاہی', 200, _karahi, _roti, 75),
  _meat(72, _b, 'Haleem', 'حلیم', 100, _stew, _roti, 300),
  _meat(73, _b, 'Paye', 'پائے', 250, _stew, _roti, 360),
  _meat(74, _b, 'Beef Pulao', 'بیف پلاؤ', 175, _riceDish, _none, 120),
  _meat(75, _b, 'Bhuna Gosht', 'بھنا گوشت', 200, _fry, _roti, 90),
  _meat(76, _b, 'Aloo Gosht', 'آلو گوشت', 150, _curry, _either, 90),
  _meat(77, _b, 'Daal Gosht', 'دال گوشت', 125, _curry, _either, 90),
  _meat(78, _b, 'Bihari Boti', 'بہاری بوٹی', 200, _bbq, _roti, 60),

  // Mutton
  _meat(
    80,
    _m,
    'Mutton Karahi',
    'مٹن کڑاہی',
    225,
    _karahi,
    _roti,
    75,
    group: 'mutton_karahi',
  ),
  _meat(81, _m, 'Mutton Qorma', 'مٹن قورمہ', 200, _curry, _roti, 90),
  _meat(
    82,
    _m,
    'Shinwari Karahi',
    'شنواری کڑاہی',
    250,
    _karahi,
    _roti,
    60,
    group: 'mutton_karahi',
  ),
  _meat(
    83,
    _m,
    'Mutton Yakhni Pulao',
    'مٹن یخنی پلاؤ',
    200,
    _riceDish,
    _none,
    120,
  ),
  _meat(84, _m, 'Namkeen Gosht', 'نمکین گوشت', 250, _stew, _roti, 120),
  _meat(85, _m, 'Mutton Biryani', 'مٹن بریانی', 200, _riceDish, _none, 120),

  // Mince (qeema)
  _meat(90, _q, 'Aloo Qeema', 'آلو قیمہ', 125, _curry, _roti, 40),
  _meat(91, _q, 'Matar Qeema', 'مٹر قیمہ', 125, _curry, _roti, 40),
  _meat(92, _q, 'Qeema Karela', 'قیمہ کریلے', 125, _fry, _roti, 60),
  _meat(93, _q, 'Shami Kebab', 'شامی کباب', 100, _fry, _roti, 90),
  _meat(94, _q, 'Kofta Curry', 'کوفتوں کا سالن', 150, _curry, _either, 75),
  _meat(95, _q, 'Seekh Kebab', 'سیخ کباب', 175, _bbq, _roti, 60),
  _meat(96, _q, 'Qeema Pulao', 'قیمہ پلاؤ', 125, _riceDish, _none, 60),
  _meat(97, _q, 'Shimla Mirch Qeema', 'شملہ مرچ قیمہ', 125, _fry, _roti, 40),
  _meat(98, _q, 'Chapli Kebab', 'چپلی کباب', 175, _fry, _roti, 45),
  _meat(99, _q, 'Daal Qeema', 'دال قیمہ', 100, _curry, _either, 50),
]);

/// Curated main → vegetable side pairings. Lower priority is preferred.
const List<DishPairing> pakistaniPairings = [
  DishPairing(mainDishId: 50, sideDishId: 2), // chicken karahi + bhindi
  DishPairing(mainDishId: 50, sideDishId: 20, priority: 1), // + aloo bhujia
  DishPairing(mainDishId: 51, sideDishId: 2), // white karahi + bhindi
  DishPairing(mainDishId: 52, sideDishId: 4), // handi + aloo matar
  DishPairing(mainDishId: 53, sideDishId: 9), // qorma + mixed sabzi
  DishPairing(mainDishId: 56, sideDishId: 21), // jalfrezi + aloo tamatar
  DishPairing(mainDishId: 57, sideDishId: 8), // butter chicken + palak paneer
  DishPairing(mainDishId: 59, sideDishId: 2), // achari chicken + bhindi
  DishPairing(mainDishId: 71, sideDishId: 20), // beef karahi + aloo bhujia
  DishPairing(mainDishId: 75, sideDishId: 2), // bhuna gosht + bhindi
  DishPairing(mainDishId: 75, sideDishId: 12, priority: 1), // + arvi
  DishPairing(mainDishId: 78, sideDishId: 3), // bihari boti + bharta
  DishPairing(mainDishId: 80, sideDishId: 1), // mutton karahi + aloo gobi
  DishPairing(mainDishId: 81, sideDishId: 4), // mutton qorma + aloo matar
  DishPairing(mainDishId: 90, sideDishId: 2), // aloo qeema + bhindi
  DishPairing(mainDishId: 91, sideDishId: 16), // matar qeema + gobi masala
  DishPairing(mainDishId: 93, sideDishId: 15), // shami kebab + aloo palak
  DishPairing(mainDishId: 94, sideDishId: 1), // kofta curry + aloo gobi
  DishPairing(mainDishId: 95, sideDishId: 3), // seekh kebab + bharta
];
