// lcSensorData.h: interface for the lcSensorData class.
//
//////////////////////////////////////////////////////////////////////

#if !defined(AFX_LCSENSORDATA_H__CDF4FABF_6BC7_455C_A93E_045DE26C91C4__INCLUDED_)
#define AFX_LCSENSORDATA_H__CDF4FABF_6BC7_455C_A93E_045DE26C91C4__INCLUDED_

#if _MSC_VER > 1000
#pragma once
#endif // _MSC_VER > 1000

#include "..\..\include\lc_support.h"

class lcSensorData  
{

public:
	typedef enum S_TYPE{ALL=0, GOOD, BAD};

	
	bool getOriMatrixD(double **output,S_TYPE type = GOOD);
	bool getPosMatrixD(double **output,S_TYPE type = GOOD);
	int getNumberOfVirtualSensors();
	int getNumberOfBadSensors();
	int getNumberOfGoodSensors();
	int getNumberOfSensors();
	bool setSensorFlag(int index, int flag);
	bool load(FILE *fp);
	bool save(FILE *fp);
	void reset();


	typedef struct PARAMS{
		char sens_name[20];
		int number;

		int flag;

		double xpos;
		double ypos;
		double zpos;

		double xori;
		double yori;
		double zori;

		int MRIxpos;
		int MRIypos;
		int MRIzpos;

		double MRIxori;
		double MRIyori;
		double MRIzori;
	};
	
	bool getNextSensor(PARAMS *sens_info);
	bool getFirstSensor(PARAMS *sens_info);
	bool getLastSensor(PARAMS *sens_info);
	bool getSensor(int number, PARAMS *sens_info);
	void addSensor(char *name, int number, double xpos, double ypos, double zpos,double xori, double yori, double zori,int MRIxpos, int MRIypos, int MRIzpos, double MRIxori, double MRIyori, double MRIzori);
	lcSensorData();
	virtual ~lcSensorData();

private:
	lc_itemsList<PARAMS> sens;

};

#endif // !defined(AFX_LCSENSORDATA_H__CDF4FABF_6BC7_455C_A93E_045DE26C91C4__INCLUDED_)
