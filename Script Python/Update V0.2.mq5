//+------------------------------------------------------------------+
//|                                                  Update V0.2.mq5 |
//|                                  Copyright 2026, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"


input string apiBaseUrl = "https://fwwodpgnhzausnxkubgf.supabase.co/functions/v1/trading-accounts-api";
input string apiKey     = "5cb27452e46975f9a55e93d427d8f57eef429044cb87300043b1112549e50113";

double initial_deposit;
double additional_deposits;
double total_deposits;
double total_withdrawals;
double current_balance;
double profit_loss;
double return_30_days;
string risk_level;
string account_type;
double total_net_profit;
double gross_profit;
double gross_loss;
double total_trades;
double winning_trades;
double winning_trades_percent;
double losing_trades;
double losing_trades_percent;
double long_trades;
double long_trades_result;
double short_trades;
double short_trades_result;
double expected_payoff;
double profit_factor;
double drawdown_absolute;
double drawdown_relative;
double recovery_factor;
double sharpe_ratio;
double avg_profit_trade;
double avg_loss_trade;
double max_consecutive_wins;
double max_consecutive_losses;
double largest_profit_trade;
double largest_loss_trade;
datetime operations_start_date;
datetime operations_end_date;
double risk_per_trade_avg;
double risk_per_trade_max;
double risk_per_trade_min;
double exposure_current;
double exposure_max;
double exposure_avg;
double rr_ratio_avg;
double rr_ratio_best;
double rr_ratio_worst;




string daily_json = "[";
string current_day = "";
int day_trades = 0;
double day_profit = 0;

string weekly_profits = "[";

//+------------------------------------------------------------------+
//| Script program start function                                    |
//+------------------------------------------------------------------+
void OnStart()
  {
//---
   Sleep(5000);
   info_account(initial_deposit,
                additional_deposits,
                total_deposits,
                total_withdrawals,
                current_balance,
                profit_loss,
                return_30_days,
                risk_level,
                account_type,
                total_net_profit,
                gross_profit,
                gross_loss,
                total_trades,
                winning_trades,
                winning_trades_percent,
                losing_trades,
                losing_trades_percent,
                long_trades,
                long_trades_result,
                short_trades,
                short_trades_result,
                expected_payoff,
                profit_factor,
                drawdown_absolute,
                drawdown_relative,
                recovery_factor,
                sharpe_ratio,
                avg_profit_trade,
                avg_loss_trade,
                max_consecutive_wins,
                max_consecutive_losses,
                largest_profit_trade,
                largest_loss_trade,
                operations_start_date,
                operations_end_date,
                risk_per_trade_avg,
                risk_per_trade_max,
                risk_per_trade_min,
                exposure_current,
                exposure_max,
                exposure_avg,
                rr_ratio_avg,
                rr_ratio_best,
                rr_ratio_worst);

   Print("Para la cuenta ", IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)), ", empieza la actualización de los datos");

   ApiUpdateAccountInfo(IntegerToString(AccountInfoInteger(ACCOUNT_LOGIN)));
//---
  }
//+------------------------------------------------------------------+




//+------------------------------------------------------------------+
//| HTTP wrapper (FIX: len sin '\0')                                 |
//+------------------------------------------------------------------+
int HttpRequest(string method, string url, string headers, string body,
                string &responseOut, string &responseHeadersOut)
  {
   string cookie = "";
   char data[];
   char result[];
   int data_len = 0;

   if(StringLen(body) > 0)
     {
      // 1) Crear buffer limpio con tamaño exacto
      // Obtener bytes UTF-8 en uchar[], sin terminador, y copiar a char[]
      uchar ubuf[];
      int ulen = StringToCharArray(body, ubuf, 0, WHOLE_ARRAY, CP_UTF8);
      // ulen incluye '\0' final, quitamos 1
      ulen = ulen - 1;
      if(ulen < 0)
         ulen = 0;

      ArrayResize(data, ulen);
      for(int i = 0; i < ulen; i++)
         data[i] = (char)ubuf[i];

      data_len = ulen;
     }
   else
     {
      ArrayResize(data, 0);
      data_len = 0;
     }

   ResetLastError();
   int code = WebRequest(method, url, cookie, headers, 8000, data, data_len, result, responseHeadersOut);

   if(code == -1)
     {
      int err = GetLastError();
      PrintFormat("WebRequest ERROR. GetLastError()=%d | url=%s", err, url);
      responseOut = "";
      return -1;
     }

   responseOut = CharArrayToString(result);
   return code;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//| Helpers                                                          |
//+------------------------------------------------------------------+
string Trim(string s)
  {
   StringTrimLeft(s);
   StringTrimRight(s);
   return s;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string URLEncode(string str)
  {
   string encoded = "";
   uchar ch;
   int len = StringLen(str);

   for(int i = 0; i < len; i++)
     {
      ch = (uchar)str[i];

      if((ch >= '0' && ch <= '9') ||
         (ch >= 'A' && ch <= 'Z') ||
         (ch >= 'a' && ch <= 'z') ||
         ch == '-' || ch == '_' || ch == '.' || ch == '~')
        {
         encoded += CharToString(ch);
        }
      else
        {
         string hex = IntegerToString((int)ch, 16);
         if(StringLen(hex) == 1)
            hex = "0" + hex;

         StringToUpper(hex);
         encoded += "%" + hex;
        }
     }

   return encoded;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string Snippet(string s, int maxLen)
  {
   if(StringLen(s) > maxLen)
      return StringSubstr(s, 0, maxLen) + "...";
   return s;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double Profit()
  {
   double profit = 0;

   for(int i = 0; i<PositionsTotal(); i++)
      if(PositionSelectByTicket(PositionGetTicket(i)))
         profit = profit + PositionGetDouble(POSITION_PROFIT)  + PositionGetDouble(POSITION_SWAP);

   return profit;
  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
string DateTimeToISO(datetime dt)
  {
   MqlDateTime t;
   TimeToStruct(dt, t);

   return StringFormat("%04d-%02d-%02dT%02d:%02d:%02dZ",
                       t.year, t.mon, t.day,
                       t.hour, t.min, t.sec);
  }
//+------------------------------------------------------------------+



//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int ApiUpdateAccountInfo(string mt5_id)
  {
   string k = Trim(apiKey);
   string url = apiBaseUrl + "?api_key=" + URLEncode(k);
   string headers = "Content-Type: application/json\r\n";

   string body = StringFormat(
                    "{"
                    "\"mt5_id\":\"%s\","
                    "\"initial_deposit\":%.2f,"
                    "\"additional_deposit\":%.2f,"
                    "\"total_deposits\":%.2f,"
                    "\"total_withdrawals\":%.2f,"
                    "\"current_balance\":%.2f,"
                    "\"profit_loss\":%.2f,"
                    "\"return_30_days\":%.2f,"
                    "\"risk_level\":\"%s\","
                    "\"account_type\":\"%s\","
                    "\"total_net_profit\":%.2f,"
                    "\"gross_profit\":%.2f,"
                    "\"gross_loss\":%.2f,"
                    "\"total_trades\":%d,"
                    "\"winning_trades\":%d,"
                    "\"winning_trades_percent\":%.2f,"
                    "\"losing_trades\":%d,"
                    "\"losing_trades_percent\":%.2f,"
                    "\"long_trades\":%d,"
                    "\"long_trades_result\":%.2f,"
                    "\"short_trades\":%d,"
                    "\"short_trades_result\":%.2f,"
                    "\"expected_payoff\":%.4f,"
                    "\"profit_factor\":%.4f,"
                    "\"drawdown_absolute\":%.2f,"
                    "\"drawdown_relative\":%.2f,"
                    "\"recovery_factor\":%.4f,"
                    "\"sharpe_ratio\":%.4f,"
                    "\"avg_profit_trade\":%.2f,"
                    "\"avg_loss_trade\":%.2f,"
                    "\"max_consecutive_wins\":%d,"
                    "\"max_consecutive_losses\":%d,"
                    "\"largest_profit_trade\":%.2f,"
                    "\"largest_loss_trade\":%.2f,"
                    "\"operations_start_date\":\"%s\","
                    "\"operations_end_date\":\"%s\","
                    "\"risk_per_trade_avg\":%.2f,"
                    "\"risk_per_trade_max\":%.2f,"
                    "\"risk_per_trade_min\":%.2f,"
                    "\"exposure_current\":%.2f,"
                    "\"exposure_max\":%.2f,"
                    "\"exposure_avg\":%.2f,"
                    "\"rr_ratio_avg\":%.4f,"
                    "\"rr_ratio_best\":%.4f,"
                    "\"rr_ratio_worst\":%.4f,"
                    "\"daily_operations\":%s,"
                    "\"weekly_profits\":%s"
                    "}",
                    mt5_id,
                    initial_deposit,
                    additional_deposits,
                    total_deposits,
                    total_withdrawals,
                    current_balance,
                    profit_loss,
                    return_30_days,
                    risk_level,
                    account_type,
                    total_net_profit,
                    gross_profit,
                    gross_loss,
                    (int)total_trades,
                    (int)winning_trades,
                    winning_trades_percent,
                    (int)losing_trades,
                    losing_trades_percent,
                    (int)long_trades,
                    long_trades_result,
                    (int)short_trades,
                    short_trades_result,
                    expected_payoff,
                    profit_factor,
                    drawdown_absolute,
                    drawdown_relative,
                    recovery_factor,
                    sharpe_ratio,
                    avg_profit_trade,
                    avg_loss_trade,
                    (int)max_consecutive_wins,
                    (int)max_consecutive_losses,
                    largest_profit_trade,
                    largest_loss_trade,
                    DateTimeToISO(operations_start_date),
                    DateTimeToISO(operations_end_date),
                    risk_per_trade_avg,
                    risk_per_trade_max,
                    risk_per_trade_min,
                    exposure_current,
                    exposure_max,
                    exposure_avg,
                    rr_ratio_avg,
                    rr_ratio_best,
                    rr_ratio_worst,
                    daily_json,
                    weekly_profits
                 );

   Print("DateTimeToISO(operations_start_date): ", DateTimeToISO(operations_start_date));
   Print("DateTimeToISO(operations_end_date): ", DateTimeToISO(operations_end_date));

   Print("risk_level: ", risk_level);
   string response = "";
   string respHeaders = "";

   PrintFormat("PUT BodyLen=%d", StringLen(body));

   int code = HttpRequest("PUT", url, headers, body, response, respHeaders);

   PrintFormat("PUT HTTP=%d | mt5_id=%s", code, mt5_id);
   Print("PUT Response=", Snippet(response, 300));

   return code;
  }

//+------------------------------------------------------------------+

double daily_balance_start = 0;
double daily_balance_current = 0;

double sum_daily_returns = 0;
double sum_daily_squared = 0;
int    daily_count = 0;

string sharpe_current_day = "";
double sharpe_day_profit = 0;


double Array_Week[4];
double Array_Week_Percent[4];
double Clossing_Balance[4];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void info_account(double &_initial_deposit,
                  double &_additional_deposits,
                  double &_total_deposits,
                  double &_total_withdrawals,
                  double &_current_balance,
                  double &_profit_loss,
                  double &_return_30_days,
                  string &_risk_level,
                  string &_account_type,
                  double &_total_net_profit,
                  double &_gross_profit,
                  double &_gross_loss,
                  double &_total_trades,
                  double &_winning_trades,
                  double &_winning_trades_percent,
                  double &_losing_trades,
                  double &_losing_trades_percent,
                  double &_long_trades,
                  double &_long_trades_result,
                  double &_short_trades,
                  double &_short_trades_result,
                  double &_expected_payoff,
                  double &_profit_factor,
                  double &_drawdown_absolute,
                  double &_drawdown_relative,
                  double &_recovery_factor,
                  double &_sharpe_ratio,
                  double &_avg_profit_trade,
                  double &_avg_loss_trade,
                  double &_max_consecutive_wins,
                  double &_max_consecutive_losses,
                  double &_largest_profit_trade,
                  double &_largest_loss_trade,
                  datetime &_operations_start_date,
                  datetime &_operations_end_date,
                  double &_risk_per_trade_avg,
                  double &_risk_per_trade_max,
                  double &_risk_per_trade_min,
                  double &_exposure_current,
                  double &_exposure_max,
                  double &_exposure_avg,
                  double &_rr_ratio_avg,
                  double &_rr_ratio_best,
                  double &_rr_ratio_worst)
  {
//-----------Inicializar variables

   _initial_deposit        = 0;
   _additional_deposits    = 0;
   _total_deposits         = 0;
   _total_withdrawals      = 0;
   _current_balance        = 0;
   _profit_loss            = 0;
   _return_30_days         = 0;
   _risk_level             = "Medio";
   _account_type           = "";
   _total_net_profit       = 0;
   _gross_profit           = 0;
   _gross_loss             = 0;
   _total_trades           = 0;
   _winning_trades         = 0;
   _winning_trades_percent = 0;
   _losing_trades          = 0;
   _losing_trades_percent  = 0;
   _long_trades            = 0;
   _long_trades_result     = 0;
   _short_trades           = 0;
   _short_trades_result    = 0;
   _expected_payoff        = 0;
   _profit_factor          = 0;
   _drawdown_absolute      = 0;
   _drawdown_relative      = 0;
   _recovery_factor        = 0;
   _sharpe_ratio           = 0;
   _avg_profit_trade       = 0;
   _avg_loss_trade         = 0;
   _max_consecutive_wins   = 0;
   _max_consecutive_losses = 0;
   _largest_profit_trade   = 0;
   _largest_loss_trade     = 0;
   _operations_start_date  = 0;
   _operations_end_date    = TimeCurrent();
   _risk_per_trade_avg     = 0;
   _risk_per_trade_max     = 0;
   _risk_per_trade_min     = 0;
   _exposure_current       = 0;
   _exposure_max           = 0;
   _exposure_avg           = 0;//Se va a quitar
   _rr_ratio_avg           = 0;
   _rr_ratio_best          = 0;
   _rr_ratio_worst         = 0;

   double sum_returns = 0;
   double sum_squared_returns = 0;
   int    n_returns = 0;


   _current_balance  = AccountInfoDouble(ACCOUNT_BALANCE);
   Print("Hola: ");
   int type_account  = (int)AccountInfoInteger(ACCOUNT_TRADE_MODE);

   if(type_account == ACCOUNT_TRADE_MODE_DEMO)
      _account_type = "DEMO";
   else
      _account_type = "REAL";


   double balance = _current_balance;
   double peak = 0;
   int con_win = 0;
   int con_los = 0;

   double risk    = 0;
   double reward  = 0;

   datetime from_30        = TimeCurrent() - (30 * 24 * 60 * 60);
   double balance_temp     = _current_balance;
   double balance_30_days  = 0;
   double _week_profit     = 0;
   double _week_return     = 0;


   datetime now = TimeCurrent();

   MqlDateTime s;
   TimeToStruct(now, s);
   int dow = s.day_of_week;

   datetime today_00       = now - (s.hour*3600 + s.min*60 + s.sec);
   int days_from_monday    = (dow == 0 ? 6 : dow - 1);
   datetime monday_current = today_00 - days_from_monday * 86400;
   datetime monday_last    = monday_current - 7 * 86400;
   datetime sunday_last    = monday_current - 1;  // domingo 23:59:59


   ArrayInitialize(Array_Week, 0.0);
   ArrayInitialize(Array_Week_Percent, 0.0);
   ArrayInitialize(Clossing_Balance, 0.0);

   double balance_day = _current_balance;

   if(HistorySelect(0,TimeCurrent()))
      for(int i = HistoryDealsTotal() - 1; i >= 0; i--)
        {
         ulong ticket   = HistoryDealGetTicket(i);
         datetime time  = (datetime)HistoryDealGetInteger(ticket,DEAL_TIME);
         int deal_type  = (int)HistoryDealGetInteger(ticket, DEAL_TYPE);

         MqlDateTime time_deal = {};
         TimeToStruct(time, time_deal);

         int week_index       = -1;
         datetime deal_time   = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);

         if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
           {
            week_index     = (int)((monday_current - deal_time) / 604800);
            double profit  = HistoryDealGetDouble(ticket, DEAL_PROFIT)
                             + HistoryDealGetDouble(ticket, DEAL_COMMISSION)
                             + HistoryDealGetDouble(ticket, DEAL_SWAP);

            if(week_index >= 0 && week_index <= 3 && deal_time < monday_current)
               Array_Week[week_index] += profit;

            if(deal_time >= from_30)
               balance_temp -= profit;
           }


         // Closing Balance
         if(week_index == 0 && Clossing_Balance[week_index] == 0 && time_deal.day_of_week <= 5 && deal_time < monday_current)
           {
            Clossing_Balance[week_index] = balance_day;
           }
         else
            if(week_index == 1 && Clossing_Balance[week_index] == 0 && time_deal.day_of_week <= 5 && deal_time < monday_current)
              {
               Clossing_Balance[week_index] = balance_day;
              }
            else
               if(week_index == 2 && Clossing_Balance[week_index] == 0 && time_deal.day_of_week <= 5 && deal_time < monday_current)
                 {
                  Clossing_Balance[week_index] = balance_day;
                 }
               else
                  if(week_index == 3 && Clossing_Balance[week_index] == 0 && time_deal.day_of_week <= 5 && deal_time < monday_current)
                    {
                     Clossing_Balance[week_index] = balance_day;
                    }

         // Depositos / Retiros /Profits
         if(HistoryDealGetInteger(ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT || HistoryDealGetInteger(ticket, DEAL_TYPE) == DEAL_TYPE_BALANCE)
            balance_day -= HistoryDealGetDouble(ticket, DEAL_PROFIT) + HistoryDealGetDouble(ticket, DEAL_COMMISSION) + HistoryDealGetDouble(ticket, DEAL_SWAP);


        }

   for(int i=0;i<ArraySize(Array_Week);i++)
     {
      Array_Week[i] = NormalizeDouble(Array_Week[i], 3);
      Array_Week_Percent[i] = Clossing_Balance[i] > 0 ? NormalizeDouble(Array_Week[i] * 100 / Clossing_Balance[i], 2) : 0;

      //Print("Array_Week[", i, "]: ", Array_Week[i]);
      //Print("Clossing_Balance[", i, "]: ", Clossing_Balance[i]);
      //Print("Array_Week_Percent[", i, "]: ", Array_Week_Percent[i]);
     }

   int j = 1;
   for(int i = 3; i >= 0; i--)
     {
      weekly_profits += "{";
      weekly_profits += "\"week\":\"" + "Sem " + IntegerToString(j) + "\",";
      weekly_profits += "\"profit\":" + DoubleToString(Array_Week_Percent[i], 2) + ",";
      weekly_profits += "\"profit_usd\":" + DoubleToString(Array_Week[i], 2) + ",";
      weekly_profits += "\"closing_balance\":" + DoubleToString(Clossing_Balance[i], 2);
      weekly_profits += "}";

      if(i > 0)
         weekly_profits += ",";

      j++;
     }

   weekly_profits += "]";


   balance_30_days = balance_temp;
   if(balance_30_days > 0)
      _return_30_days = NormalizeDouble(((_current_balance - balance_30_days) / balance_30_days) * 100.0,2);


   if(HistorySelect(0,TimeCurrent()))
      for(int i = 0; i < HistoryDealsTotal(); i++)
        {
         ulong Ticket   = HistoryDealGetTicket(i);
         int deal_type  = (int)HistoryDealGetInteger(Ticket, DEAL_TYPE);



         if(deal_type == DEAL_ENTRY_IN)
           {
            if(_operations_start_date == 0)
               _operations_start_date = (datetime)HistoryDealGetInteger(Ticket,DEAL_TIME);

            _operations_end_date = (datetime)HistoryDealGetInteger(Ticket,DEAL_TIME);
           }


         if(HistoryDealGetInteger(Ticket, DEAL_ENTRY) == DEAL_ENTRY_OUT)
           {
            double profit     = HistoryDealGetDouble(Ticket,DEAL_PROFIT) + HistoryDealGetDouble(Ticket,DEAL_COMMISSION) + HistoryDealGetDouble(Ticket,DEAL_SWAP);
            _total_net_profit = _total_net_profit + profit;
            int Type_oper     = (int)HistoryDealGetInteger(Ticket,DEAL_TYPE);
            _total_trades++;


            // ---- Sharpe data
            sum_returns += profit;
            sum_squared_returns += profit * profit;
            n_returns++;


            if(profit >= 0)
              {
               reward = profit;
               _gross_profit = _gross_profit + profit;
               _winning_trades++;
               con_win++;

               if(con_los > _max_consecutive_losses)
                  _max_consecutive_losses = con_los;

               con_los = 0;

               if(profit > _largest_profit_trade)
                  _largest_profit_trade = profit;
              }
            else
               if(profit < 0)
                 {
                  risk = MathAbs(profit);
                  con_los++;
                  _gross_loss = _gross_loss + profit;
                  _losing_trades++;

                  if(con_win > _max_consecutive_wins)
                     _max_consecutive_wins = con_win;

                  con_win = 0;

                  if(profit < _largest_loss_trade)
                     _largest_loss_trade = profit;



                  if(profit < _risk_per_trade_max*100/_current_balance)
                     _risk_per_trade_max = profit*100/_current_balance;

                  if(_risk_per_trade_min == 0)
                     _risk_per_trade_min = profit*100/_current_balance;
                  else
                     if(profit > _risk_per_trade_min*100/_current_balance)
                        _risk_per_trade_min = profit*100/_current_balance;
                 }



            if(risk > 0 && reward > 0)
              {
               double rr = reward / risk;

               if(rr > _rr_ratio_best)
                 {
                  _rr_ratio_best = rr;
                 }

               if(_rr_ratio_worst == 0 || rr < _rr_ratio_worst)
                 {
                  _rr_ratio_worst = rr;
                 }
              }


            ///---------lONG AND SHORTS
            if(Type_oper == DEAL_TYPE_BUY)
              {
               _long_trades_result = _long_trades_result + profit;
               _long_trades++;
              }
            else
               if(Type_oper == DEAL_TYPE_SELL)
                 {
                  _short_trades_result = _short_trades_result + profit;
                  _short_trades++;
                 }


            //----DD
            balance = balance + profit;
            if(balance > peak)
               peak = balance;

            double drawdown = peak - balance;

            if(drawdown > _drawdown_absolute)
               _drawdown_absolute = drawdown;



            ///--------DAILY OPERATION
            datetime deal_time = (datetime)HistoryDealGetInteger(Ticket, DEAL_TIME);


            MqlDateTime t;
            TimeToStruct(deal_time, t);

            string deal_day = StringFormat("%04d-%02d-%02d", t.year, t.mon, t.day);

            if(current_day == "")
               current_day = deal_day;

            // Si cambia el día → cerrar el día anterior
            if(deal_day != current_day)
              {
               daily_json += StringFormat(
                                "{\"date\":\"%s\",\"trades\":%d,\"profit\":%.2f},",
                                current_day,
                                day_trades,
                                day_profit
                             );

               // Reset acumuladores
               current_day = deal_day;
               day_trades = 0;
               day_profit = 0;
              }

            // Acumular datos del día
            day_trades++;
            day_profit += profit;



            //Sharpe Ratio

            TimeToStruct(deal_time, t);

            deal_day = StringFormat("%04d-%02d-%02d", t.year, t.mon, t.day);

            // Inicializar primer día
            if(sharpe_current_day == "")
              {
               sharpe_current_day = deal_day;
               daily_balance_start = balance;   // balance antes del primer profit del día
               daily_balance_current = balance;
              }

            // Si cambia el día → cerrar retorno del día anterior
            if(deal_day != sharpe_current_day)
              {
               if(daily_balance_start > 0)
                 {
                  double daily_return = sharpe_day_profit / daily_balance_start;

                  sum_daily_returns += daily_return;
                  sum_daily_squared += daily_return * daily_return;
                  daily_count++;
                 }

               // Reset para nuevo día
               sharpe_current_day = deal_day;
               sharpe_day_profit = 0;
               daily_balance_start = balance;
              }

            // Acumular profit del día
            sharpe_day_profit += profit;
            daily_balance_current += profit;


            // Cerrar último día para Sharpe
            if(daily_count >= 0 && daily_balance_start > 0)
              {
               double daily_return = sharpe_day_profit / daily_balance_start;

               sum_daily_returns += daily_return;
               sum_daily_squared += daily_return * daily_return;
               daily_count++;
              }

           }


         // Depositos / Retiros
         if(deal_type == DEAL_TYPE_BALANCE)
           {
            double amount = HistoryDealGetDouble(Ticket, DEAL_PROFIT);

            if(_initial_deposit == 0)
              {
               _initial_deposit = amount;
               continue;
              }

            if(amount > 0)
              {
               _additional_deposits += amount;       // Depósito
               _total_deposits += amount;
              }

            else
               if(amount < 0)
                  _total_withdrawals += MathAbs(amount); // Retiro
           }
        }


   _profit_loss            = NormalizeDouble(_gross_profit/MathAbs(_gross_loss), 3);
   _winning_trades_percent = NormalizeDouble(100*_winning_trades/_total_trades, 3);
   _losing_trades_percent  = NormalizeDouble(100*_losing_trades/_total_trades, 3);
   _expected_payoff        = NormalizeDouble(_total_net_profit/_total_trades, 3);
   _profit_factor          = NormalizeDouble(_gross_profit/MathAbs(_gross_loss), 3);
   _drawdown_relative      = peak == 0 ? 0 : NormalizeDouble(100*_drawdown_absolute/peak, 3);
   _recovery_factor        = _total_net_profit / _drawdown_absolute;
   _avg_profit_trade       = NormalizeDouble(_gross_profit/_winning_trades, 3);
   _avg_loss_trade         = NormalizeDouble(MathAbs(_gross_loss)/_losing_trades, 3);
   _risk_per_trade_avg     = NormalizeDouble(100*(_gross_loss/_losing_trades)/_current_balance, 3);
   _rr_ratio_avg           = NormalizeDouble(_gross_profit/MathAbs(_gross_loss), 3);
   _long_trades_result     = NormalizeDouble(_long_trades_result, 3);
   _short_trades_result    = NormalizeDouble(_short_trades_result, 3);
   _drawdown_absolute      = NormalizeDouble(_drawdown_absolute, 2);
   _exposure_max           = _drawdown_relative;
   _exposure_current       = peak == 0 ? 0 : NormalizeDouble(100*Profit()/peak, 3);
   _recovery_factor        = NormalizeDouble(_recovery_factor, 3);
   _rr_ratio_worst         = NormalizeDouble(_rr_ratio_worst, 3);
   _additional_deposits    = NormalizeDouble(_additional_deposits, 3);


   if(daily_count > 1)
     {
      double mean       = sum_daily_returns / daily_count;
      double variance   = (sum_daily_squared / daily_count) - (mean * mean);

      if(variance > 0)
        {
         double stddev = MathSqrt(variance);
         _sharpe_ratio = mean / stddev;
        }
     }

   _sharpe_ratio           = NormalizeDouble(_sharpe_ratio, 3);

   if(day_trades > 0)
     {
      daily_json += StringFormat(
                       "{\"date\":\"%s\",\"trades\":%d,\"profit\":%.2f}",
                       current_day,
                       day_trades,
                       day_profit
                    );
     }

   daily_json += "]";



   Print("_initial_deposit: ", DoubleToString(_initial_deposit, 2));
   Print("_additional_deposits: ", DoubleToString(_additional_deposits, 2));
   Print("_total_withdrawals: ", DoubleToString(_total_withdrawals, 2));
   Print("_current_balance: ", _current_balance);
   Print("_profit_loss: ", _profit_loss);
   Print("_return_30_days: ", _return_30_days);

   Print("_account_type: ", _account_type);
   Print("_total_net_profit: ", DoubleToString(_total_net_profit, 2));
   Print("_gross_profit: ", DoubleToString(_gross_profit, 2));
   Print("_gross_loss: ", DoubleToString(_gross_loss, 2));
   Print("_total_trades: ", _total_trades);
   Print("_winning_trades: ", _winning_trades);
   Print("_winning_trades_percent: ", _winning_trades_percent);
   Print("_losing_trades: ", _losing_trades);
   Print("_losing_trades_percent: ", _losing_trades_percent);
   Print("_long_trades: ", _long_trades);
   Print("_long_trades_result: ", _long_trades_result);
   Print("_short_trades: ", _short_trades);
   Print("_short_trades_result: ", _short_trades_result);
   Print("_expected_payoff: ", _expected_payoff);
   Print("_profit_factor: ", _profit_factor);
   Print("_drawdown_absolute: ", _drawdown_absolute);
   Print("_drawdown_relative: ", _drawdown_relative);
   Print("_recovery_factor: ", _recovery_factor);
   Print("_sharpe_ratio: ", _sharpe_ratio);
   Print("_avg_profit_trade: ", _avg_profit_trade);
   Print("_avg_loss_trade: ", _avg_loss_trade);
   Print("_max_consecutive_wins: ", _max_consecutive_wins);
   Print("_max_consecutive_losses: ", _max_consecutive_losses);
   Print("_largest_profit_trade: ", _largest_profit_trade);
   Print("_largest_loss_trade: ", _largest_loss_trade);
   Print("_total_deposits: ", _total_deposits);

   Print("_operations_start_date: ", _operations_start_date);
   Print("_operations_end_date: ", _operations_end_date);
   Print("_risk_per_trade_avg: ", _risk_per_trade_avg);
   Print("_risk_per_trade_max: ", _risk_per_trade_max);
   Print("_risk_per_trade_min: ", _risk_per_trade_min);
   Print("_exposure_current: ", _exposure_current);
   Print("_exposure_max: ", _exposure_max);
   Print("_rr_ratio_avg: ", _rr_ratio_avg);
   Print("_rr_ratio_best: ", _rr_ratio_best);
   Print("_rr_ratio_worst: ", _rr_ratio_worst);
   Print("daily_json: ", daily_json);
   Print("weekly_profits: ", weekly_profits);

  }
//+------------------------------------------------------------------+
