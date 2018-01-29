//+------------------------------------------------------------------+
//|                                   Copyright 2017, Erlon F. Souza |
//|                                       https://github.com/erlonfs |
//+------------------------------------------------------------------+

#property copyright "Copyright 2017, Erlon F. Souza"
#property link      "https://github.com/erlonfs"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <BadRobot.Framework\BadRobot.mqh>

class ElephantWalk : public BadRobot
{
   private:
   
   	MqlRates _rates[];   	
   	double _high;
	   double _low;	   
	   double _sizeOfBar;	   
	   bool _wait;
	   
	   bool _match;
	   datetime _timeMatch;
	   
	   //Indicadores
   	bool _ativarCruzamentoDeMedias;   	
   	int _eMALongPeriod;
   	int _eMALongHandle;
   	double _eMALongValues[];   	
   	int _eMAShortPeriod;
   	int _eMAShortHandle;
   	double _eMAShortValues[];
   	
   	bool GetBuffers() {
   	
   	   if(_wait) return true;
   	   
   	   if (_ativarCruzamentoDeMedias) {
   	   
            ZeroMemory(_rates);
         	ZeroMemory(_eMALongValues);
      		ZeroMemory(_eMAShortValues);
      		
      		ArraySetAsSeries(_rates, true);
            ArraySetAsSeries(_eMALongValues, true);
      		ArraySetAsSeries(_eMAShortValues, true);

            ArrayFree(_eMALongValues);
      		ArrayFree(_eMAShortValues);      		
      		ArrayFree(_rates);
      		
      		int copiedMALongBuffer = CopyBuffer(_eMALongHandle, 0, 0, 2, _eMALongValues);
		      int copiedMAShortBuffer = CopyBuffer(_eMAShortHandle, 0, 0, 2, _eMAShortValues);
		      int copiedRates = CopyRates(GetSymbol(), GetPeriod(), 0, 2, _rates);
		      
		      return copiedRates > 0 && copiedMALongBuffer > 0 && copiedMAShortBuffer > 0;
   	   }
   	   	
   		ZeroMemory(_rates);
   		ArraySetAsSeries(_rates, true);
   		ArrayFree(_rates); 
   
   		int copiedRates = CopyRates(GetSymbol(), GetPeriod(), 0, 2, _rates);
   
   		return copiedRates > 0;

	   }
	   
	   bool IsCandlePositive(MqlRates &rate){
	      return rate.close >= rate.open;
	   }
	   
	   bool IsCandleNegative(MqlRates &rate){
	      return rate.open > rate.close;
	   }  
	   
	   bool FindElephant(){	   
	   	   	      
         bool isFound = false;
         
         if(!GetIsNewCandle()){
            return isFound;
         }
         
	      _high = _rates[1].high;
	      _low = _rates[1].low;	     
	      
	      isFound = _high - _low  >= _sizeOfBar;
	      
	      if(isFound != _match){
	         
	         if(isFound){
	            _timeMatch = _rates[1].time;
	            Draw(_low, _timeMatch);
	         }	         
	      }
	      
	      _match = isFound;
	      	      	        	    	      	      	    	      
	      return isFound;
	   
	   }
	   
	void Draw(double price, datetime time)
	{	
		//ClearDraw(time);
		string objName = "ARROW" + (string)time;
		ObjectCreate(0, objName, OBJ_ARROW_UP, 0, time, price);

		ObjectSetInteger(0, objName, OBJPROP_COLOR, clrMagenta);
		ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
		ObjectSetInteger(0, objName, OBJPROP_BACK, false);
		ObjectSetInteger(0, objName, OBJPROP_FILL, true);
	}

	void ClearDraw(datetime time) {

		string objName = "ARROW" + (string)time;

		if (ObjectFind(0, objName) != 0) {
			ObjectDelete(0, objName);
		}
	}
   
   public:
      
   	void Load() 
   	{
         if(!_ativarCruzamentoDeMedias) return;
	   
		   _eMALongHandle = iMA(GetSymbol(), GetPeriod(), _eMALongPeriod, 0, MODE_EMA, PRICE_CLOSE);
		   _eMAShortHandle = iMA(GetSymbol(), GetPeriod(), _eMAShortPeriod, 0, MODE_EMA, PRICE_CLOSE);

   		if (_eMALongHandle < 0 || _eMAShortHandle < 0) {
   			Alert("Erro ao criar indicadores: erro ", GetLastError(), "!");
   		}
   	};
   
   	void Execute() {
   	
   	   BadRobot::SetInfo("TAM CANDLE "+ (string)(_high - _low) + "/" + (string)_sizeOfBar + 
   	                 "\nMIN "+ (string)_low + " MAX " + (string)_high);
   	   
   	   if(!BadRobot::ExecuteBase()) return;
      		
   		if(GetBuffers()){   	
   		      		   
   		   if(_wait || FindElephant()){
   		   
   		      _wait = true;
   		         		     
      		   if(IsCandlePositive(_rates[1]) && _eMAShortValues[0] > _eMALongValues[0]){
      		         		      		   
      		      double _entrada = _high + GetSpread();
         			double _auxStopGain = NormalizeDouble((_entrada + GetStopGain()), _Digits);
         			double _auxStopLoss = NormalizeDouble((_entrada - GetStopLoss()), _Digits);
              
         			if (GetPrice().last >= _entrada && !HasPositionOpen()) {         
         			   _wait = false;
         				Buy(_entrada, _auxStopLoss, _auxStopGain, getRobotName());           				          
         			}         		
         			
      		   }
      		   
      		   if(IsCandleNegative(_rates[1]) && _eMAShortValues[0] < _eMALongValues[0]){
      		         		   
      		      double _entrada = _low - GetSpread();
         			double _auxStopGain = NormalizeDouble((_entrada - GetStopGain()), _Digits);
         			double _auxStopLoss = NormalizeDouble((_entrada + GetStopLoss()), _Digits);
              
         			if (GetPrice().last <= _entrada && !HasPositionOpen()) {         
         			   _wait = false;
         				Sell(_entrada, _auxStopLoss, _auxStopGain, getRobotName());     
        			   }         		         			
      		   }
   		      
               if(GetPrice().last < _low - GetSpread()){
      			   _wait = false;
      			   ShowMessage("COMPRA CANCELADA!");
      			   return;
      			}      			      			
      			
      			if(GetPrice().last > _high + GetSpread()){
      			   _wait = false;
      			   ShowMessage("VENDA CANCELADA!");
      			   return;
      			}
      		  
            }
   		   
   		}   	
   		
   	};
   	
      void ExecuteOnTrade(){
         BadRobot::ExecuteOnTradeBase();         
         _wait = false;
      }
      
      void SetSizeOfBar(double value){
         _sizeOfBar = value;
      }  

   	void SetAtivarCruzamentoDeMedias(int flag) {
   		_ativarCruzamentoDeMedias = flag;
   	}
      
   	void SetEMALongPeriod(int ema) {
   		_eMALongPeriod = ema;
   	};
   
   	void SetEMAShortPeriod(int ema) {
   		_eMAShortPeriod = ema;
   	};   
   	
};

