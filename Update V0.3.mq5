//+------------------------------------------------------------------+
//|                                                  Update V0.3.mq5 |
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
//Sleep(5000);

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
   int type_account  = (int)AccountInfoInteger(ACCOUNT_TRADE_MODE);

   if(type_account == ACCOUNT_TRADE_MODE_DEMO)
      _account_type = "DEMO";
   else
      _account_type = "REAL";

   double balance = _current_balance;



//----------------Profit diario, profit en los ultimos 30 días y profit en las ultimas 4 semanas
   double _week_profit     = 0;
   double _week_return     = 0;


   datetime now = TimeCurrent();

   MqlDateTime s;
   TimeToStruct(now, s);
   int dow = s.day_of_week;

   datetime today_00       = now - (s.hour*3600 + s.min*60 + s.sec);
   int days_from_monday    = (dow == 0 ? 6 : dow - 1);
   datetime monday_current = today_00 - days_from_monday * 86400;

   ArrayInitialize(Array_Week, 0.0);
   ArrayInitialize(Array_Week_Percent, 0.0);
   ArrayInitialize(Clossing_Balance, 0.0);


   double Array_Profit_Daily[];
   double Array_Percent_Daily[];
   double Array_Balance_Start_Day[];
   double Array_Commision[];
   int    Number_Trades[];
   datetime Array_Date[];

   int total_days = 0;


   MqlDateTime dt_start;
   TimeToStruct(TimeCurrent(), dt_start);

   dt_start.hour  = 0;
   dt_start.min   = 0;
   dt_start.sec   = 0;
   datetime ini_day_oper = StructToTime(dt_start);
   datetime end_day_oper = ini_day_oper - (30 * 86400);


   if(HistorySelect(0, TimeCurrent()))
     {
      int total = HistoryDealsTotal();

      datetime _current_day   = 0;
      double daily_profit     = 0;
      double daily_commission = 0;
      double running_balance  = AccountInfoDouble(ACCOUNT_BALANCE);

      int trades           = 0;
      datetime day_time    = TimeCurrent();
      bool first           = false;

      for(int i = total - 1; i >= 0; i--)
        {
         ulong ticket = HistoryDealGetTicket(i);

         datetime deal_time = (datetime)HistoryDealGetInteger(ticket, DEAL_TIME);
         long type          = HistoryDealGetInteger(ticket, DEAL_TYPE);
         long entry         = HistoryDealGetInteger(ticket, DEAL_ENTRY);

         double profit     = HistoryDealGetDouble(ticket, DEAL_PROFIT);
         double commission = HistoryDealGetDouble(ticket, DEAL_COMMISSION);
         double swap       = HistoryDealGetDouble(ticket, DEAL_SWAP);
         double net_profit = profit + swap ;


         MqlDateTime dt;
         TimeToStruct(deal_time, dt);

         dt.hour  = 0;
         dt.min   = 0;
         dt.sec   = 0;
         day_time = StructToTime(dt);

         if(day_time != _current_day)
           {
            if(_current_day != 0)
              {
               ArrayResize(Array_Profit_Daily, total_days);
               ArrayResize(Array_Balance_Start_Day, total_days);
               ArrayResize(Array_Date, total_days);
               ArrayResize(Array_Percent_Daily, total_days);
               ArrayResize(Number_Trades, total_days);
               ArrayResize(Array_Commision, total_days);
               ArrayResize(Array_Date, total_days);
               running_balance -= (daily_profit + daily_commission);

               Array_Profit_Daily[total_days-1]      = NormalizeDouble(daily_profit + daily_commission, 2);
               Array_Balance_Start_Day[total_days-1] = NormalizeDouble(running_balance, 2);
               Array_Commision[total_days-1]         = NormalizeDouble(daily_commission, 2);
               Number_Trades[total_days-1]           = trades;
               Array_Date[total_days-1]              = _current_day;

               if(running_balance != 0)
                  Array_Percent_Daily[total_days-1] =
                     NormalizeDouble(100.0 * daily_profit / running_balance, 2);
               else
                  Array_Percent_Daily[total_days-1] = 0;
              }

            _current_day = day_time;
            daily_profit = 0;
            daily_commission = 0;
            trades = 0;
            total_days++;
           }

         if(type == DEAL_TYPE_BALANCE || type == DEAL_TYPE_CREDIT)
           {
            int new_balance = (int)(running_balance - profit);

            if(new_balance > 0)
               running_balance -= profit;

           }

         if(type == DEAL_TYPE_BUY || type == DEAL_TYPE_SELL)
            daily_commission += commission;


         if((entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY || entry == DEAL_ENTRY_IN) &&
            (type == DEAL_TYPE_BUY || type == DEAL_TYPE_SELL))
           {
            _total_net_profit += profit + swap + commission;

            ///---------PROFIT AND LOSS

            if(profit + swap + commission > 0)
              {
               _gross_profit += profit + swap + commission;

               if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
                  _winning_trades++;
              }
            else
              {
               _gross_loss += profit + swap + commission;

               if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
                  _losing_trades++;
              }

            daily_profit += net_profit;
            trades++;

            ///---------lONG AND SHORTS
            if(type == DEAL_TYPE_BUY)
              {
               _long_trades_result = _long_trades_result + profit + swap + commission;

               if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
                  _long_trades++;
              }
            else
               if(type == DEAL_TYPE_SELL)
                 {
                  _short_trades_result = _short_trades_result + profit + swap + commission;

                  if(entry == DEAL_ENTRY_OUT || entry == DEAL_ENTRY_OUT_BY)
                     _short_trades++;
                 }

            ///---------AVG PROFIT Y AVG LOSS
            if(profit + swap + commission > _largest_profit_trade)
               _largest_profit_trade = profit + swap + commission;

            if(profit + swap + commission < _largest_loss_trade)
               _largest_loss_trade = profit + swap + commission;
           }
        }


      if(total_days > 0)
        {
         ArrayResize(Array_Profit_Daily, total_days);
         ArrayResize(Array_Balance_Start_Day, total_days);
         ArrayResize(Array_Date, total_days);
         ArrayResize(Array_Percent_Daily, total_days);
         ArrayResize(Number_Trades, total_days);
         ArrayResize(Array_Commision, total_days);
         ArrayResize(Array_Date, total_days);
         running_balance -= (daily_profit + daily_commission);

         Array_Profit_Daily[total_days-1]      = NormalizeDouble(daily_profit + daily_commission, 2);
         Array_Balance_Start_Day[total_days-1] = NormalizeDouble(running_balance, 2);
         Array_Commision[total_days-1]         = NormalizeDouble(daily_commission, 2);
         Number_Trades[total_days-1]           = trades;
         Array_Date[total_days-1]              = _current_day;

         if(running_balance != 0)
            Array_Percent_Daily[total_days-1] =
               NormalizeDouble(100.0 * daily_profit / running_balance, 2);
         else
            Array_Percent_Daily[total_days-1] = 0;
        }
     }

   double Profit_30_days      = 0;
   double Balance_30_day_Ago  = balance;


   for(int L = 0; L < ArraySize(Array_Profit_Daily); L++)
     {
      if(Array_Date[L] >= end_day_oper)
        {
         Profit_30_days       += Array_Profit_Daily[L];
         Balance_30_day_Ago   = Array_Balance_Start_Day[L];
        }

      //----------Seccion profit semanal
      int week_index     = (int)((monday_current - (Array_Date[L] + 1)) / 604800);

      if(week_index >= 0 && week_index <= 3 && Array_Date[L] < monday_current)
        {
         Array_Week[week_index]           += Array_Profit_Daily[L];
         Array_Week_Percent[week_index]   += Array_Percent_Daily[L];
         Clossing_Balance[week_index]     = Array_Balance_Start_Day[L] > Clossing_Balance[week_index] ? Array_Balance_Start_Day[L]  : Clossing_Balance[week_index];
        }
     }

   _return_30_days = NormalizeDouble(Profit_30_days*100 / Balance_30_day_Ago, 3);


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


   for(int L = 0; L < ArraySize(Array_Profit_Daily); L++)
     {

      ///--------DAILY OPERATION
      MqlDateTime t;
      TimeToStruct(Array_Date[L], t);

      string deal_day = StringFormat("%04d-%02d-%02d", t.year, t.mon, t.day);

      if(L == ArraySize(Array_Profit_Daily) - 1)
         daily_json += StringFormat(
                          "{\"date\":\"%s\",\"trades\":%d,\"profit\":%.2f}",
                          deal_day,
                          Number_Trades[L],
                          Array_Profit_Daily[L]
                       );
      else
         daily_json += StringFormat(
                          "{\"date\":\"%s\",\"trades\":%d,\"profit\":%.2f},",
                          deal_day,
                          Number_Trades[L],
                          Array_Profit_Daily[L]
                       );

     }

   daily_json += "]";

   double peak = 0;
   int con_win = 0;
   int con_los = 0;

   double risk    = 0;
   double reward  = 0;
   if(HistorySelect(0,TimeCurrent()))
      for(int i = 0; i < HistoryDealsTotal(); i++)
        {
         ulong Ticket   = HistoryDealGetTicket(i);

         int deal_type  = (int)HistoryDealGetInteger(Ticket, DEAL_TYPE);
         int deal_entry = (int)HistoryDealGetInteger(Ticket, DEAL_ENTRY);


         if(deal_type == DEAL_ENTRY_IN)
           {
            if(_operations_start_date == 0)
               _operations_start_date = (datetime)HistoryDealGetInteger(Ticket,DEAL_TIME);

            _operations_end_date = (datetime)HistoryDealGetInteger(Ticket,DEAL_TIME);
           }


         if((deal_type == DEAL_ENTRY_OUT || deal_type == DEAL_ENTRY_OUT_BY) &&
            (deal_entry == DEAL_TYPE_BUY || deal_entry == DEAL_TYPE_SELL))
           {
            double profit     = HistoryDealGetDouble(Ticket,DEAL_PROFIT) + HistoryDealGetDouble(Ticket,DEAL_COMMISSION) + HistoryDealGetDouble(Ticket,DEAL_SWAP);
            _total_trades++;

            //----DD
            balance = balance + profit;
            if(balance > peak)
               peak = balance;

            double drawdown = peak - balance;

            if(drawdown > _drawdown_absolute)
               _drawdown_absolute = drawdown;


            //--------------Consecutive LOSS AND WIN
            if(profit >= 0)
              {
               if(con_los > _max_consecutive_losses)
                  _max_consecutive_losses = con_los;

               con_los = 0;
               con_win++;
              }
            else
               if(profit < 0)
                 {
                  if(con_win > _max_consecutive_wins)
                     _max_consecutive_wins = con_win;

                  con_win = 0;
                  con_los++;
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

   _rr_ratio_avg           = NormalizeDouble(_gross_profit/MathAbs(_gross_loss), 3);
   _long_trades_result     = NormalizeDouble(_long_trades_result, 3);
   _short_trades_result    = NormalizeDouble(_short_trades_result, 3);
   _drawdown_absolute      = NormalizeDouble(_drawdown_absolute, 2);
   _exposure_max           = _drawdown_relative;
   _exposure_current       = peak == 0 ? 0 : NormalizeDouble(100*Profit()/peak, 3);
   _recovery_factor        = NormalizeDouble(_recovery_factor, 3);
   _rr_ratio_worst         = NormalizeDouble(_rr_ratio_worst, 3);
   _additional_deposits    = NormalizeDouble(_additional_deposits, 3);
   _sharpe_ratio           = NormalizeDouble(CalculateSharpe(Array_Percent_Daily), 3);
   _total_deposits         = NormalizeDouble(_total_deposits + _initial_deposit, 3);


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
   Print("_exposure_current: ", _exposure_current);
   Print("_exposure_max: ", _exposure_max);
   Print("_rr_ratio_avg: ", _rr_ratio_avg);
   Print("_rr_ratio_best: ", _rr_ratio_best);
   Print("_rr_ratio_worst: ", _rr_ratio_worst);
   Print("daily_json: ", daily_json);
   Print("weekly_profits: ", weekly_profits);

  }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateSharpe(double &returns[])
  {
   int n = ArraySize(returns);
   if(n < 2)
      return 0.0;

   double sum = 0.0;

// Promedio
   for(int i = 0; i < n; i++)
      sum += returns[i];

   double mean = sum / n;

// Desviación estándar
   double variance = 0.0;
   for(int i = 0; i < n; i++)
      variance += MathPow(returns[i] - mean, 2);

   variance /= (n - 1);
   double stddev = MathSqrt(variance);

   if(stddev == 0.0)
      return 0.0;

   double sharpe = mean / stddev;

   return NormalizeDouble(sharpe,3);
  }
//+------------------------------------------------------------------+
