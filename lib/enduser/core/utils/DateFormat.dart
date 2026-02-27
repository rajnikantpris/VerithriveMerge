import 'package:intl/intl.dart';

class DateFormats{

  static var dateFormatDDMMYYYY="dd/MM/yyyy, hh:mm a";
  static var dateFormatYYYYMMDDHHMM="yyyy-MM-dd HH:mm:ss";

 static String dateFormat(String inputDateFormat,String outputDateFormat,String date){

    var inputFormat = DateFormat(inputDateFormat);
    var inputDate = inputFormat.parse(date);

    var outputFormat = DateFormat(outputDateFormat);
    var outputDate = outputFormat.format(inputDate);

    return outputDate;

   /* var inputFormat = DateFormat('dd/MM/yyyy HH:mm');
    var inputDate = inputFormat.parse('31/12/2000 23:59'); // <-- dd/MM 24H format

    var outputFormat = DateFormat('MM/dd/yyyy hh:mm a');
    var outputDate = outputFormat.format(inputDate)*/;

  }

 static String convertDateFormat(dateTimeString, String oldFormat, String newFormat) {

   /// Convert into local date format.
   var localDate = DateTime.parse(dateTimeString).toLocal();
   var inputFormat = DateFormat(oldFormat);
   var inputDate = inputFormat.parse(localDate.toString());
   /// outputFormat - convert into format you want to show.
   var outputFormat = DateFormat(newFormat);
   var outputDate = outputFormat.format(inputDate);
   return outputDate.toString();

 }

}