//+------------------------------------------------------------------+
//|                                   Copyright 2017, Erlon F. Souza |
//|                                       https://github.com/erlonfs |
//+------------------------------------------------------------------+

#property copyright "Copyright 2017, Erlon F. Souza"
#property link      "https://github.com/erlonfs"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <BadRobot.Framework\BadRobotPrompt.mqh>

class ElephantWalk : public BadRobotPrompt
{
   private:
   
   	MqlRates _rates[];   	
   	double _high;
		double _low;	   
		int _sizeOfBar;	   
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
   	   
   	   if (_ativarCruzamentoDeMedias) 
   	   {   	   
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
         
         if(!IsNewCandle())
         {
            return isFound;
         }
         
	      _high = _rates[1].high;
	      _low = _rates[1].low;	     
	      
	      isFound = ToPoints(_high - _low)  >= ToPoints(_sizeOfBar);
	      
	      bool isCandlePositive = IsCandlePositive(_rates[1]);
	      
	      if(isFound != _match){
	         
	         if(isFound)
	         {
	            _timeMatch = _rates[1].time;
	            Draw(isCandlePositive ? _high : _low, _timeMatch, isCandlePositive);
	            ShowMessage("Barra elefante de " + DoubleToString(ToPoints(_sizeOfBar), _Digits) + " encontrado.");
	         }	         
	      }
	      
	      _match = isFound;
	      	      	        	    	      	      	    	      
	      return isFound;
	   
	   }
	   
	void Draw(double price, datetime time, bool isCandlePositive)
	{	
		//ClearDraw(time);
		string objName = "ARROW" + DoubleToString(price) + TimeToString(time);
		ObjectCreate(0, objName, OBJ_ARROW_UP, 0, time, price);

		ObjectSetInteger(0, objName, OBJPROP_COLOR, isCandlePositive ? clrGreen : clrRed);
		ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
		ObjectSetInteger(0, objName, OBJPROP_BACK, false);
		ObjectSetInteger(0, objName, OBJPROP_FILL, true);
		ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, isCandlePositive ? clrGreen : clrRed);
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
   		LoadBase();
   	
         if(!_ativarCruzamentoDeMedias) return;
	   
		   _eMALongHandle = iMA(GetSymbol(), GetPeriod(), _eMALongPeriod, 0, MODE_EMA, PRICE_CLOSE);
		   _eMAShortHandle = iMA(GetSymbol(), GetPeriod(), _eMAShortPeriod, 0, MODE_EMA, PRICE_CLOSE);

   		if (_eMALongHandle < 0 || _eMAShortHandle < 0) {
   			Alert("Erro ao criar indicadores: erro ", GetLastError(), "!");
   		}
   	};
   	
      void UnLoad(const int reason)
   	{
         UnLoadBase(reason);
   	};   	
   
   	void Execute() {
   	
   	   SetInfo("TAM CANDLE "+ DoubleToString(_high - _low, _Digits) + "/" + DoubleToString(ToPoints(_sizeOfBar), _Digits) + 
   	                 "\nMIN "+ DoubleToString(_low, _Digits) + " MAX " + DoubleToString(_high, _Digits));
   	   
   	   if(!ExecuteBase()) return;
      		
   		if(GetBuffers()){   	
   		      		   
   		   if(_wait || FindElephant()){
   		   
   		      _wait = true;
   		         		     
      		   if(IsCandlePositive(_rates[1]) && (_ativarCruzamentoDeMedias ? _eMAShortValues[0] > _eMALongValues[0] : true)){
      		         		      		   
      		      double _entrada = _high + ToPoints(GetSpread());         			
              
         			if (GetLastPrice() >= _entrada && !HasPositionOpen()) {         
         			   _wait = false;
         				Buy(_entrada);           				          
         			}             		     		
         			
      		   }
      		   
      		   if(IsCandleNegative(_rates[1]) && (_ativarCruzamentoDeMedias ? _eMAShortValues[0] < _eMALongValues[0] : true)){
      		         		   
      		      double _entrada = _low - ToPoints(GetSpread());
              
         			if (GetLastPrice() <= _entrada && !HasPositionOpen()) {         
         			   _wait = false;
         				Sell(_entrada);     
        			   }         		         			
      		   }
   		      
               if(GetLastPrice() < _low - ToPoints(GetSpread())){
      			   _wait = false;
      			   ShowMessage("Compra Cancelada!");
      			   return;
      			}      			      			
      			
      			if(GetLastPrice() > _high + ToPoints(GetSpread())){
      			   _wait = false;
      			   ShowMessage("Venda Cancelada!");
      			   return;
      			}
      		  
            }
   		   
   		}   	
   		
   	};
   	
      void ExecuteOnTrade()
      {
         ExecuteOnTradeBase();         
         _wait = false;
      }
      
      void ChartEvent(const int id, const long& lparam, const double& dparam, const string& sparam)
      {      	
			ChartEventBase(id, lparam, dparam, sparam);      	
      };      
      
      void SetSizeOfBar(int value){
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

