import 'package:flutter/material.dart';

class ArmenitiesUi extends StatefulWidget {

String type;
int startValue;
Function decreaseValue;
Function increaseValue;


 ArmenitiesUi({super.key, required this.type, required this.startValue,required this.decreaseValue , required this.increaseValue});

  @override
  State<ArmenitiesUi> createState() => _ArmenitiesUiState();
}

class _ArmenitiesUiState extends State<ArmenitiesUi> {


int? _valueDigit;


@override
  void initState() {
    // TODO: implement initState
    super.initState();

    _valueDigit= widget.startValue;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
Text(widget.type,
style: TextStyle(
  fontSize: 18
),



),


Row(
  children: <Widget>[
IconButton(
  
  onPressed: (){
widget.decreaseValue();
_valueDigit=_valueDigit!-1;

if(_valueDigit!<0){
  _valueDigit =0;
}
setState(() {
  
});
  },
  
   icon: Icon(Icons.remove)
   ),

IconButton(
  
  onPressed: (){
widget.decreaseValue();
_valueDigit=_valueDigit!-1;

if(_valueDigit!<0){
  _valueDigit =0;
}
setState(() {
  
});
  },
  
   icon: Icon(Icons.remove)
   ),

   Text(
    _valueDigit.toString(),
    style: TextStyle(
      fontSize: 20
    ),   ),


    IconButton(
  
  onPressed: (){
widget.increaseValue();
_valueDigit=_valueDigit!  + 1;


setState(() {
  
});
  },
  
   icon: Icon(Icons.add)
   ),



  ],
)

      ],);
  }
}