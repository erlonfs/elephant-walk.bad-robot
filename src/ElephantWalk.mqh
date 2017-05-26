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
   	double _high;
	   double _low;	   
	   double _sizeOfBar;	   
	   bool _wait;
   	
   	bool GetBuffers() {
   	
   	   if(_wait) return true;
   	   	
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
	   	      
	      _high = _rates[1].high;
	      _low = _rates[1].low;
	      
	      Base::SetInfo("TAM CANDLE "+ (string)_sizeOfBar + "\nMIN "+ (string)_low + " MAX " + (string)_high + "\nWAIT " + (string)_wait + "\nGetIsNewCandle() " + (string)GetIsNewCandle());
	      
	      if(_high - _low  >= _sizeOfBar)
	      {	      	        
	         return true;	         
	      }
	      	      	      
	      return false;
	   
	   }
   
   public:
      
   	void Load() 
   	{
         //TODO
   	};
   
   	void Execute() {
   	   
   	   Base::SetInfo("TAM CANDLE "+ (string)_sizeOfBar + "\nMIN "+ (string)_low + " MAX " + (string)_high + "\nWAIT " + (string)_wait + "\nGetIsNewCandle() " + (string)GetIsNewCandle());
   	
   	   if(!Base::ExecuteBase()) return;
      		
   		if(GetBuffers()){   	
   		   
   		   if(_wait || FindElephant()){
   		   
   		      _wait = true;

      		   if(IsCandlePositive(_rates[1])){
      		         		      		   
      		      double _entrada = _high + GetSpread();
         			double _auxStopGain = NormalizeDouble((_entrada + GetStopGain()), _Digits);
         			double _auxStopLoss = NormalizeDouble((_entrada - GetStopLoss()), _Digits);
              
         			if (GetPrice().last >= _entrada && !HasPositionOpen()) {         
         			   _wait = false;
         				Buy(_entrada, _auxStopLoss, _auxStopGain, getRobotName());           				          
         			}        		   
         			
      		   }
      		   
      		   if(IsCandleNegative(_rates[1])){
      		         		   
      		      double _entrada = _low - GetSpread();
         			double _auxStopGain = NormalizeDouble((_entrada - GetStopGain()), _Digits);
         			double _auxStopLoss = NormalizeDouble((_entrada + GetStopLoss()), _Digits);
              
         			if (GetPrice().last <= _entrada && !HasPositionOpen()) {         
         			   _wait = false;
         				Sell(_entrada, _auxStopLoss, _auxStopGain, getRobotName());     
         			}
         			
      		   }
      		  
            }
   		   
   		}   	
   		
   	};
   	
      void ExecuteOnTrade(){
         Base::ExecuteOnTradeBase();
      }
      
      void SetSizeOfBar(double value){
         _sizeOfBar = value;
      }     
   	
};

