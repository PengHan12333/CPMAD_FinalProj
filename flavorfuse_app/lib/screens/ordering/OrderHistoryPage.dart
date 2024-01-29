import 'package:fl_chart/fl_chart.dart';
import 'package:flavorfuse_app/screens/ordering/OrderReceiptPage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/order_history_service.dart';

class AppColors {
  static const Color gradientStart = Color(0xFF1a1a1a);
  static const Color gradientEnd = Color(0xFF000000);
  static const Color contentColorCyan = Color(0xFF00BCD4);
  static const Color contentColorBlue = Color(0xFF2196F3);
  static const Color mainGridLineColor = Color(0x2237434D);
  static const Color primaryColor = Color(0xFF2C3E50);
  static const Color accentColor = Color(0xFF3498DB);
  static const Color secondaryColor = Color(0xFFECF0F1);
}

class OrderHistoryPage extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class OrderHistoryPageState extends StatefulWidget {
  @override
  _OrderHistoryPageState createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage>
    with TickerProviderStateMixin {
  // AnimationController _animationController;
  // int _currentIndex = 2;
  List<Order> orderHistory; // Ensure it's declared as List<Order>
  List<Color> gradientColors = [
    AppColors.contentColorCyan,
    AppColors.contentColorBlue
  ];
  bool showAverageGraph = false;
  double totalAmountSpent;
  final OrderHistoryService orderHistoryService = OrderHistoryService();

  @override
  void initState() {
    super.initState();
    totalAmountSpent = 0.00; // or any default value
    fetchData();
  }

  // Fetch data asynchronously
  void fetchData() async {
    double totalAmountSpentw = await orderHistoryService
        .calculateTotalAmountSpent(orderHistoryService.getCurrentUserUid());
    // Use await to get the actual List<OrderData> from the Future
    List<Order> result = await orderHistoryService
        .getOrderHistory(orderHistoryService.getCurrentUserUid());

    // Update the state with the fetched data
    setState(() {
      orderHistory = result;
      totalAmountSpent = totalAmountSpentw;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Container(
        color: Colors.black87,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTotalAmountCard(),
              _buildRoundedContainer(
                child: _buildLineChart(),
              ),
              _buildPurchaseHistory(),
            ],
          ),
        ),
      ),
      // bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildRoundedContainer({Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
      ),
      child: child,
    );
  }

  Widget _buildAppBar() {
    return AppBar(
      iconTheme: IconThemeData(color: Colors.white),
      title: Text(
        'Statistics',
        style: GoogleFonts.nunito(
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 21,
            color: Colors.white,
          ),
        ),
      ),
      backgroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
    );
  }

  Widget _buildTotalAmountCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Total Amount Spent',
                style: GoogleFonts.openSans(
                  textStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Text(
                '\$${(totalAmountSpent ?? 0.00)?.toStringAsFixed(2) ?? "Loading..."}',
                style: GoogleFonts.nunito(
                  textStyle: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 30,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPurchaseHistory() {
    bool hasTopRoundCorners = orderHistory == null || orderHistory.length <= 4;
    return Container(
      padding: EdgeInsets.only(left: 10, right: 10, bottom: 20, top: 10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(hasTopRoundCorners ? 30 : 0),
          topRight: Radius.circular(hasTopRoundCorners ? 30 : 0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            margin: EdgeInsets.only(bottom: 13),
            child: Text(
              'Purchase History',
              style: GoogleFonts.roboto(
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          _buildOrderList(),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    bool isEmpty = orderHistory == null || orderHistory.isEmpty;

    return isEmpty
        ? Container(
            height: 370, // Set the desired fixed height
            child: Center(
              child: Text(
                'No Orders Found',
                style: GoogleFonts.quicksand(
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          )
        : Container(
            height: 460, // Set the desired fixed height
            margin: const EdgeInsets.only(bottom: 55),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final order in orderHistory)
                    Hero(
                      tag: 'order_${order.orderNumber}',
                      child: ScrollableOrderListItem(
                        order: order,
                        onTap: null,
                      ),
                    ),
                ],
              ),
            ),
          );
  }

  Widget _buildLineChart() {
    if (orderHistory == null || orderHistory.length <= 4) {
      // Return an empty container if order history length is 0
      return Container();
    }

    double screenHeight = MediaQuery.of(context).size.height;
    double chartHeight = screenHeight * 0.45;
    double radius = 0;

    return Container(
      margin: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(4.0),
            child: Text(
              "Cost Statistics",
              style: GoogleFonts.roboto(
                textStyle: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 1,
                  blurRadius: 1,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            height: chartHeight,
            padding: EdgeInsets.only(left: 20, right: 20, bottom: 20, top: 30),
            child: LineChart(
              showAverageGraph
                  ? _createAvgLineChartData()
                  : _createLineChartData(),
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                showAverageGraph = !showAverageGraph;
              });
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bar_chart_sharp, // Replace with the appropriate icon
                  color: showAverageGraph ? Colors.grey : Colors.blue,
                ),
                SizedBox(width: 8), // Adjust the spacing between icon and text
                Text(
                  'Toggle Average',
                  style: TextStyle(
                    fontSize: 16,
                    color: showAverageGraph ? Colors.grey : Colors.blue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _createAvgLineChartData() {
    double average = orderHistory.isNotEmpty
        ? orderHistory
                .map((order) => order.totalAmount)
                .reduce((sum, amount) => sum + amount) /
            orderHistory.length
        : 0.0;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 25,
        verticalInterval: 25,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.mainGridLineColor,
          strokeWidth: 2,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: AppColors.mainGridLineColor,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        bottomTitles: SideTitles(
          margin: 15,
          showTitles: true,
          reservedSize: 10,
          interval: 1,
          getTextStyles: (value) => GoogleFonts.openSans(
            textStyle: TextStyle(
              color: Colors.grey[700], // Customize text color for X-axis
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          getTitles: (value) => value.toString(),
        ),
        leftTitles: SideTitles(
          margin: 15,
          showTitles: true,
          interval: 25,
          getTextStyles: (value) => GoogleFonts.openSans(
            textStyle: TextStyle(
              color: Colors.grey[700], // Customize text color for Y-axis
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          getTitles: (value) => "\$$value",
          reservedSize: 35,
        ),
      ),
      borderData: FlBorderData(
        show: false,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: orderHistory.length.toDouble() - 1,
      minY: 0,
      maxY: orderHistory
          .map((order) => order.totalAmount)
          .reduce((max, amount) => max > amount ? max : amount),
      lineBarsData: [
        if (showAverageGraph)
          LineChartBarData(
            spots: [
              FlSpot(0, double.parse(average.toStringAsFixed(2))),
              FlSpot(orderHistory.length.toDouble() - 1,
                  double.parse(average.toStringAsFixed(2))),
            ],
            isCurved: true,
            colors: [AppColors.accentColor],
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              colors: gradientColors
                  .map((color) => color.withOpacity(0.3))
                  .toList(),
            ),
          ),
      ],
    );
  }

  LineChartData _createLineChartData() {
    List<FlSpot> spots = List.generate(
      orderHistory.length,
      (index) => FlSpot(index.toDouble(), orderHistory[index].totalAmount),
    );

    // Calculate the average
    double average = orderHistory
            .map((order) => order.totalAmount)
            .reduce((sum, amount) => sum + amount) /
        orderHistory.length;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 25,
        verticalInterval: 25,
        getDrawingHorizontalLine: (value) => FlLine(
          color: AppColors.mainGridLineColor,
          strokeWidth: 2,
        ),
        getDrawingVerticalLine: (value) => FlLine(
          color: AppColors.mainGridLineColor,
          strokeWidth: 1,
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: SideTitles(showTitles: false),
        topTitles: SideTitles(showTitles: false),
        bottomTitles: SideTitles(
          margin: 15,
          showTitles: true,
          reservedSize: 10,
          interval: 1,
          getTextStyles: (value) => GoogleFonts.openSans(
            textStyle: TextStyle(
              color: Colors.grey[700], // Customize text color for X-axis
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          getTitles: (value) => value.toString(),
        ),
        leftTitles: SideTitles(
          margin: 15,
          showTitles: true,
          interval: 25,
          getTextStyles: (value) => GoogleFonts.openSans(
            textStyle: TextStyle(
              color: Colors.grey[700], // Customize text color for Y-axis
              fontWeight: FontWeight.w600,
              fontSize: 12.5,
            ),
          ),
          getTitles: (value) => "\$$value",
          reservedSize: 35,
        ),
      ),
      borderData: FlBorderData(
        show: false,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: orderHistory.length.toDouble() - 1,
      minY: 0,
      maxY: orderHistory
          .map((order) => order.totalAmount)
          .reduce((max, amount) => max > amount ? max : amount),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          colors: gradientColors,
          barWidth: 4,
          isStrokeCapRound: true,
          belowBarData: BarAreaData(
            show: true,
            colors:
                gradientColors.map((color) => color.withOpacity(0.3)).toList(),
          ),
        ),
        if (showAverageGraph) // Conditionally add the average line
          LineChartBarData(
            spots: [
              FlSpot(0, average),
              FlSpot(orderHistory.length.toDouble() - 1, average),
            ],
            isCurved: true,
            colors: [AppColors.accentColor],
            barWidth: 4,
            isStrokeCapRound: true,
          ),
      ],
    );
  }
}

class ScrollableOrderListItem extends StatelessWidget {
  final Order order;
  final Function onTap;

  const ScrollableOrderListItem({Key key, this.order, this.onTap})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.all(6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => OrderReceipt(
                    order:
                        order)), // Replace YourNewScreen with the actual screen you want to navigate to
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOrderNumber(),
              SizedBox(height: 4),
              _buildOrderDateAndPrice(),
              SizedBox(height: 2),
              _buildRestaurantName(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderNumber() {
    return Text(
      'Order #${order.orderNumber}',
      style: GoogleFonts.openSans(
        textStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  Widget _buildOrderDateAndPrice() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.date_range,
              size: 18,
              color: Colors.black,
            ),
            SizedBox(width: 4),
            Text(
              '${order.formattedDate}',
              style: GoogleFonts.nunito(
                textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
        Text(
          '- \$${order.totalAmount.toStringAsFixed(2)}',
          style: GoogleFonts.nunitoSans(
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRestaurantName() {
    return Row(
      children: [
        Icon(
          Icons.restaurant,
          size: 18,
          color: Colors.black,
        ),
        SizedBox(width: 4),
        Container(
          width: 270,
          child: Text(
            '${order.restaurantName}',
            style: GoogleFonts.nunito(
              textStyle: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
