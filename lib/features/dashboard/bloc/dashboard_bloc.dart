import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:crypto_eth_wallet/models/transaction_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/io.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc() : super(DashboardInitial()) {
    on<DashboardInitialFechEvent>(dashboardInitialFechEvent);
    on<DashboardDepositEvent>(dashboardDepositEvent);
    on<DashboardWithdrawEvent>(dashboardWithdrawEvent);
  }

  List<TransactionModel> transactions = [];
  Web3Client? _web3Client;
  late ContractAbi _abiCode;
  late EthereumAddress _contractAddress;
  late EthPrivateKey _creds;
  int balance = 0;

  // Functions
  late DeployedContract _deployedContract;
  late ContractFunction _deposit;
  late ContractFunction _withdraw;
  late ContractFunction _getBalance;
  late ContractFunction _getAllTransactions;

  FutureOr<void> dashboardInitialFechEvent(
      DashboardInitialFechEvent event, Emitter<DashboardState> emit) async {
    emit(DashboardLoadingState());
    try {
      String rpcUrl =
          Platform.isAndroid ? 'http://10.0.2.2:7545' : "http://127.0.0.1:7545";
      String socketUrl =
          Platform.isAndroid ? 'http://10.0.2.2:7545' : "ws://127.0.0.1:7545/";
      String privateKey =
          "0xe78df48e93fbf011bba6f81e6f44619f95298c7eedd84bfb24fbf209569613c5";

      _web3Client = Web3Client(
        rpcUrl,
        http.Client(),
        socketConnector: () {
          return IOWebSocketChannel.connect(socketUrl).cast<String>();
        },
      );

      // getABI
      String abiFile = await rootBundle
          .loadString('build/contracts/ExpenseManagerContract.json');
      var jsonDecoded = jsonDecode(abiFile);

      _abiCode = ContractAbi.fromJson(
          jsonEncode(jsonDecoded["abi"]), 'ExpenseManagerContract');

      _contractAddress =
          EthereumAddress.fromHex("0x4CC87F97762E3EB52825E132709b37B2A0057Bcd");

      _creds = EthPrivateKey.fromHex(privateKey);

      // get deployed contract
      _deployedContract = DeployedContract(_abiCode, _contractAddress);
      _deposit = _deployedContract.function("deposit");
      _withdraw = _deployedContract.function("withdraw");
      _getBalance = _deployedContract.function("getBalance");
      _getAllTransactions = _deployedContract.function("getAllTransaction");
      // final transactionsData = [];
      final transactionsData = await _web3Client!.call(
          contract: _deployedContract,
          function: _getAllTransactions,
          params: []);
      // if (transactionsData[0].isEmpty) {
      //   // Handle empty transactions data
      //   emit(DashboardSuccessState(transactions: [], balance: balance));
      //   return;
      // }
      final balanceData = await _web3Client!
          .call(contract: _deployedContract, function: _getBalance, params: [
        EthereumAddress.fromHex("0xdcBf0f0be025e0E7af5E93F8bC69c92C59960c8D")
      ]);
      List<TransactionModel> trans = [];
      log(balanceData.toString());
      for (int i = 0; i < transactionsData[0].length; i++) {
        TransactionModel transactionModel = TransactionModel(
            transactionsData[0][i].toString(),
            transactionsData[1][i].toInt(),
            transactionsData[2][i],
            DateTime.fromMicrosecondsSinceEpoch(
                transactionsData[3][i].toInt()));
        trans.add(transactionModel);
      }
      transactions = trans;

      int bal = balanceData[0].toInt();
      balance = bal;

      emit(DashboardSuccessState(transactions: transactions, balance: balance));
    } catch (e) {
      log('Tell ${e.toString()}');
      emit(DashboardErrorState());
    }
  }

  FutureOr<void> dashboardDepositEvent(
      DashboardDepositEvent event, Emitter<DashboardState> emit) async {
    try {
      final transaction = Transaction.callContract(
        from: EthereumAddress.fromHex(
            "0xdcBf0f0be025e0E7af5E93F8bC69c92C59960c8D"),
        contract: _deployedContract,
        function: _deposit,
        parameters: [
          BigInt.from(event.transactionModel.amount),
          event.transactionModel.reason
        ],
        value: EtherAmount.inWei(BigInt.from(event.transactionModel.amount)),
      );

      final result = await _web3Client!.sendTransaction(_creds, transaction,
          chainId: 1337, fetchChainIdFromNetworkId: false);
      log(result.toString());
      add(DashboardInitialFechEvent());
    } catch (e) {
      log(e.toString());
    }
  }

  FutureOr<void> dashboardWithdrawEvent(
      DashboardWithdrawEvent event, Emitter<DashboardState> emit) async {
    try {
      final transaction = Transaction.callContract(
        from: EthereumAddress.fromHex(
            "0xdcBf0f0be025e0E7af5E93F8bC69c92C59960c8D"),
        contract: _deployedContract,
        function: _withdraw,
        parameters: [
          BigInt.from(event.transactionModel.amount),
          event.transactionModel.reason
        ],
      );

      final result = await _web3Client!.sendTransaction(_creds, transaction,
          chainId: 1337, fetchChainIdFromNetworkId: false);
      log(result.toString());
      add(DashboardInitialFechEvent());
    } catch (e) {
      log(e.toString());
    }
  }
}
