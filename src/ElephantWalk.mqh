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
	   
	   bool _match;
	   datetime _timeMatch;
   	
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
	   	   	      
         bool isFound = false;
         
         if(!Base::GetIsNewCandle()){
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
         //TODO
   	};
   
   	void Execute() {
   	
   	   Base::SetInfo("TAM CANDLE "+ (string)(_high - _low) + "/" + (string)_sizeOfBar + 
   	                 "\nMIN "+ (string)_low + " MAX " + (string)_high);
   	   
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
      		   
      		   MqlTick lastPrice = GetPrice();
   		      
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
         Base::ExecuteOnTradeBase();         
         _wait = false;
      }
      
      void SetSizeOfBar(double value){
         _sizeOfBar = value;
      }     
   	
};

