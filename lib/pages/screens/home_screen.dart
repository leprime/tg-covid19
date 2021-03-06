import 'dart:async';
import 'dart:convert';
import 'package:covid_tracker/blocs/blocs.dart';
import 'package:covid_tracker/pages/widgets/global_card.dart';
import 'package:covid_tracker/theme/color/light_color.dart';
import 'package:covid_tracker/utils/calculateGrowth.dart';
import 'package:covid_tracker/utils/margin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:responsive_screen/responsive_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin {
  Completer<void> _refreshCompleter;
  String url = "https://thevirustracker.com/free-api?countryTotal=TG";
  List data1;
  List data2;

  Future<String> makeRequest() async {
    var response = await http
        .get(Uri.encodeFull(url), headers: {"Accept": "application/json"});

    setState(() {
      var extractContrydata = json.decode(response.body);
      var extractContryNewdata = json.decode(response.body);
      data1 = extractContrydata["countrydata"];
      data2 = extractContryNewdata["countrynewsitems"];
    });
  }

  @override
  void initState() {
    super.initState();
    _refreshCompleter = Completer<void>();
    this.makeRequest();
  }

  @override
  void didChangeDependencies() {
    BlocProvider.of<CaseBloc>(context).add(FetchCase());

    //do whatever you want with the bloc here.
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final Function wp = Screen(context).wp;
    final Function hp = Screen(context).hp;
    return SingleChildScrollView(
        padding: EdgeInsets.only(top: 20),
        child: BlocBuilder<CaseBloc, CaseState>(
          builder: (BuildContext context, CaseState state) {
            print(state);
            if (state is CaseLoading) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  YMargin(hp(29)),
                  Center(
                      child: SpinKitSquareCircle(
                    color: CardColors.green,
                    size: 50.0,
                  )),
                ],
              );
            }
            if (state is CaseLoaded) {
              final currentData = state.currentData;
              final firstData = state.firstData;
              return RefreshIndicator(
                child: Column(
                  children: <Widget>[
                    GlobalSituationCard(
                      cardTitle: 'Cas Confirmés',
                      caseTitle: 'Confirmés',
                      currentData: data1[0]["total_cases"],
                      newData: data1[0]["total_new_cases_today"],
                      icon: showGrowthIcon(data1[0]["total_cases"],
                          data1[0]["total_new_cases_today"]),
                      color: Colors.red,
                    ),
                    GlobalSituationCard(
                      cardTitle: 'Cas Gueris',
                      caseTitle: 'Gueris',
                      currentData: data1[0]["total_recovered"],
                      newData:
                      null,
                      cardColor: CardColors.blue,
                      icon: Icon(
                        Icons.arrow_upward,
                        color: Colors.green,
                      ),
                      color: Colors.green,
                    ),
                    GlobalSituationCard(
                      cardTitle: 'Cas de Decès',
                      caseTitle: 'Decès',
                      currentData: data1[0]["total_deaths"],
                      newData: data1[0]["total_new_deaths_today"],
                      icon: showGrowthIcon(data1[0]["total_deaths"],
                          data1[0]["total_new_deaths_today"]),
                      color: Colors.red,
                      cardColor: CardColors.red,
                    ),
                    SizedBox(height: hp(3)),
                    GlobalSituationCard(
                      cardTitle: 'Cas Graves',
                      caseTitle: 'Graves',
                      currentData: data1[0]["total_serious_cases"],
                      newData: null,
                      icon: showGrowthIcon(data1[0]["total_serious_cases"],
                          firstData.totalSeriousCases),
                      color: Colors.red,
                      cardColor: CardColors.cyan,
                    ),
                    SizedBox(height: hp(3)),
                  ],
                ),
                onRefresh: () {
                  BlocProvider.of<CaseBloc>(context).add(FetchCase());
                  return _refreshCompleter.future;
                },
              );
            }
            if (state is CaseError) {
              return Text(
                'Veullez verifier votre connexion internet!',
                style:
                    GoogleFonts.cabin(textStyle: TextStyle(color: Colors.red)),
              );
            }
            return Center(
                child: RefreshIndicator(
              child: Text('Pull to refresh'),
              onRefresh: () {
                BlocProvider.of<CaseBloc>(context).add(FetchCase());
                return _refreshCompleter.future;
              },
            ));
          },
          // listener: (BuildContext context, CaseState state) {
          //   if (state is CaseLoaded) {
          //     BlocProvider.of<CaseBloc>(context).add(FetchCase());
          //   }
          // }
        ));
  }

  @override
  bool get wantKeepAlive => true;
}
