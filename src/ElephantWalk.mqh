//+------------------------------------------------------------------+
//|                                   Copyright 2017, Erlon F. Souza |
//|                                       https://github.com/erlonfs |
//+------------------------------------------------------------------+

#property copyright "Copyright 2017, Erlon F. Souza"
#property link      "https://github.com/erlonfs"

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Framework\Base.mqh>

class ElephantWalk : public Base
{
   private:
   
   	MqlRates _rates[];
   	ENUM_TIMEFRAMES _period;   
   	
   	double _high;
	   double _low;
   	
   	bool GetBuffers() {

   		if (!IsNewCandle()) {
   			return ArraySize(_rates) > 0;
   		}
   
   		ZeroMemory(_rates);
   		ArraySetAsSeries(_rates, true);
   		ArrayFree(_rates); 
   
   		int copiedRates = CopyRates(GetSymbol(), GetPeriod(), 0, 3, _rates);
   
   		return copiedRates > 0;

	   }
	   
	   bool IsCandlePositive(MqlRates &rate){
	      return rate.close >= rate.open;
	   }
	   
	   bool IsCandleNegative(MqlRates &rate){
	      return rate.open > rate.close;
	   }  
	   
	   bool FindElephant(){
	   	      
	      _high = _rates[1].high;
	      _low = _rates[1].low;
	      
	      return true;
	   
	   }
   
   public:
      
   	void Load() 
   	{
         //TODO
   	};
   
   	void Execute() {
   	
   	   if(!Base::ExecuteBase()) return;
      		
   		if(GetBuffers()){
   		   
   		   if(!FindElephant()){
   		      return;
   		   }
   		   
   		   if(IsCandlePositive(_rates[1])){
   		      		   
   		      double _entrada = _high + GetSpread();
      			double _auxStopGain = NormalizeDouble((_entrada + GetStopGain()), _Digits);
      			double _auxStopLoss = NormalizeDouble((_entrada - GetStopLoss()), _Digits);
           
      			if (GetPrice().ask >= _entrada && !HasPositionOpen()) {         
      				Buy(_entrada, _auxStopLoss, _auxStopGain, getRobotName());            
      			}        		   
      			
   		   }
   		   
   		   if(IsCandleNegative(_rates[1])){
   		   
   		      double _entrada = _low - GetSpread();
      			double _auxStopGain = NormalizeDouble((_entrada - GetStopGain()), _Digits);
      			double _auxStopLoss = NormalizeDouble((_entrada + GetStopLoss()), _Digits);
           
      			if (GetPrice().bid <= _entrada && !HasPositionOpen()) {         
      				Sell(_entrada, _auxStopLoss, _auxStopGain, getRobotName());            
      			}
      			
   		   }
   		   
   		}
   		   		
   		Base::ShowInfo();
   		
   	};
};

