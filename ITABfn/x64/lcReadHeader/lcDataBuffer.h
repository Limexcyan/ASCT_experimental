// lcDataBuffer.h: interface for the lcDataBuffer class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_LCDATABUFFER_H__4A0C503E_A703_47AA_A719_900996781C94__INCLUDED_)
#define AFX_LCDATABUFFER_H__4A0C503E_A703_47AA_A719_900996781C94__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "lcsensordata.h"

class lcDataBuffer  
{
public:
	double *** getAllEpochsBL();
	double *** getAllEpochs(int t=0);
	typedef enum lcDBerrorType{     DBE_NONE = 0,
									DBE_NO_DATA, 
									DBE_NO_BASELINE,
									DBE_NO_DATA_PARAMETERS,
									DBE_SUBSET_EMPTY,
									DBE_MEMORY
								};


	lcDBerrorType getError();
	void setTimeResolution(int tr);
	int getSubSetSpan();
	int getSubSet(int index);
	void setAbsSubSet(int a, int b);
	void setRelSubSet(int a, int b);
	void reselectChannels(lcSensorData *sd);
	double ** getValue(int e, int t=0);
	double getValue(int e, int c, int s, int t=0);
	int getStartData();
	void setStartData(int start);
	void setTgOffset(int value){ offsetFromTrigger = value; };
	int	 getTgOffset(){ return offsetFromTrigger; };
	void setValue(int e, double **timematrix, int t = 0);
	void setValue(int e, int c, double *timeline , int t = 0);
	void setValue(int e, int c, int s, double value, int t=0);
	bool isInitialized();
	void reset();
	int getPoints();
	int getEpochs();
	int getChannels();
	int getTimeResolution();
	int getTimeInstants();
	void initialize(int ne, int nc, int ns, int tc = 1, int neBL = 0, int nsBL = 0);

	// base line
	double ** getValueBL(int e);
	double getValueBL(int e, int c, int s);
	void setValueBL(int e, double **timematrix);
	void setValueBL(int e, int c, double *timeline);
	void setValueBL(int e, int c, int s, double value);
	void setAbsSubSetBL(int a, int b);
	void setRelSubSetBL(int a, int b);
	int getSubSetSpanBL();
	int getSubSetBL(int index);
	int getPointsBL();
	void setBaseLineOffset(int value){ offsetDataBL = value; };
	int	 getBaseLineOffset(){ return offsetDataBL; };
	int getEpochsBL();

	
	
	
	lcDataBuffer(int ne, int nc, int ns, int tc= 1,int neBL = 0,  int nsBL = 0);
	lcDataBuffer();
	virtual ~lcDataBuffer();

private:
	void freeData();
	int startData;
	int offsetFromTrigger;
	int subset[2];
	int nsmpl;
	int ntimes;
	int timeres;
	int nepochs;
	double ****data;

	int startDataBL;
	int offsetDataBL;
	int subsetBL[2];
	int nsmplBL;
	int nepochsBL;
	double ***dataBL;

	void initialize();
	int nchans;

	lcDBerrorType error;
	
};

#endif // !defined(AFX_LCDATABUFFER_H__4A0C503E_A703_47AA_A719_900996781C94__INCLUDED_)
