// lcSensorData.cpp: implementation of the lcSensorData class.
//
//////////////////////////////////////////////////////////////////////

#include "lcSensorData.h"

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

lcSensorData::lcSensorData()
{
	reset();
}

lcSensorData::~lcSensorData()
{
	reset();
}

void lcSensorData::addSensor(char *name, int number, double xpos, double ypos, double zpos,double xori, double yori, double zori,int MRIxpos, int MRIypos, int MRIzpos, double MRIxori, double MRIyori, double MRIzori)
{
	PARAMS local;
	
	if(name!=NULL) strcpy(local.sens_name,name);
	else local.sens_name[0] = 0;

	local.number = number;

	local.xpos = xpos;
	local.ypos = ypos;
	local.zpos = zpos;

	local.MRIxpos = MRIxpos;
	local.MRIypos = MRIypos;
	local.MRIzpos = MRIzpos;
	
	local.xori = xori;
	local.yori = yori;
	local.zori = zori;

	local.MRIxori = MRIxori;
	local.MRIyori = MRIyori;
	local.MRIzori = MRIzori;
	
	local.flag = true;

	sens.add(local,number);

}

bool lcSensorData::getSensor(int number, PARAMS *sens_info)
{
	if(sens.getValue(number,sens_info)==NULL) return false;
	return true;
}

void lcSensorData::reset()
{
	sens.clear();
}

bool lcSensorData::save(FILE *fp)
{
	PARAMS item;
	bool result;

	fwrite((char*)"SENSOR",7*sizeof(char),1,fp);

	int count = sens.count();
	fwrite((char*)&count,sizeof(int),1,fp);
	
	result = sens.getFirstValue(&item);
	while(result){
		fwrite((char*)&item,sizeof(PARAMS),1,fp);
		result = sens.getNextValue(&item);
	}
	
	return true;
}

bool lcSensorData::load(FILE *fp)
{
	PARAMS item;
	char datapart[7];
	int count;

	sens.clear();

	fread((char*)datapart,7*sizeof(char),1,fp);

	if(strcmp(datapart,"SENSOR")) return false;

	fread((char*)&count,sizeof(int),1,fp);

	for(int i=0;i<count;i++){
		fread((char*)&item,sizeof(PARAMS),1,fp);
		sens.add(item,item.number);
	}

	return true;

}


bool lcSensorData::getFirstSensor(PARAMS *sens_info)
{
	return sens.getFirstValue(sens_info);
}

bool lcSensorData::getLastSensor(PARAMS *sens_info)
{
	return sens.getLastValue(sens_info);
}

bool lcSensorData::getNextSensor(PARAMS *sens_info)
{
	return sens.getNextValue(sens_info);
}

bool lcSensorData::setSensorFlag(int index, int flag)
{
	PARAMS item;

	if(!sens.getValue(index,&item)) return false;

	item.flag = flag;

	return sens.set(index,item);
}

int lcSensorData::getNumberOfSensors()
{
	return sens.count();
}

int lcSensorData::getNumberOfGoodSensors()
{
	bool result;
	PARAMS temp;
	int count = 0;

	result = this->getFirstSensor(&temp);
	while(result) {
		if(temp.flag==0) count++;
		result = this->getNextSensor(&temp);
	}

	return count;
}

int lcSensorData::getNumberOfBadSensors()
{
	bool result;
	PARAMS temp;
	int count = 0;

	result = this->getFirstSensor(&temp);
	while(result) {
		if(temp.flag!=0) count++;
		result = this->getNextSensor(&temp);
	}

	return count;
}

int lcSensorData::getNumberOfVirtualSensors()
{
	bool result;
	PARAMS temp;
	int count = 0;

	result = this->getFirstSensor(&temp);
	while(result) {
		if(temp.flag==10) count++;
		result = this->getNextSensor(&temp);
	}

	return count;

}

bool lcSensorData::getPosMatrixD(double **output,S_TYPE type )
{
	bool result;
	PARAMS temp;
	int count = 0;

	if(!output) return false;

	result = this->getFirstSensor(&temp);

	switch(type){
	case ALL:
		while(result) {
			if(temp.flag!=10){
				output[count][0] = temp.xpos;
				output[count][1] = temp.ypos;
				output[count][2] = temp.zpos;
				count++;
			}
			result = this->getNextSensor(&temp);
		}
		return true;
	case GOOD:
		while(result) {
			if(temp.flag==0){
				output[count][0] = temp.xpos;
				output[count][1] = temp.ypos;
				output[count][2] = temp.zpos;
				count++;
			}
			result = this->getNextSensor(&temp);
		}
		return true;
	case BAD:
		while(result) {
			if( (temp.flag!=0) && (temp.flag!=10) ){
				output[count][0] = temp.xpos;
				output[count][1] = temp.ypos;
				output[count][2] = temp.zpos;
				count++;
			}
			result = this->getNextSensor(&temp);
		}
		return true;
	default:
		return false;
	}


}

bool lcSensorData::getOriMatrixD(double **output,S_TYPE type )
{
	bool result;
	PARAMS temp;
	int count = 0;

	if(!output) return false;

	result = this->getFirstSensor(&temp);

	switch(type){
	case ALL:
		while(result) {
			if(temp.flag!=10){
				output[count][0] = temp.xori;
				output[count][1] = temp.yori;
				output[count][2] = temp.zori;
				count++;
			}
			result = this->getNextSensor(&temp);
		}
		return true;
	case GOOD:
		while(result) {
			if(temp.flag==0){
				output[count][0] = temp.xori;
				output[count][1] = temp.yori;
				output[count][2] = temp.zori;
				count++;
			}
			result = this->getNextSensor(&temp);
		}
		return true;
	case BAD:
		while(result) {
			if( (temp.flag!=0) && (temp.flag!=10) ){
				output[count][0] = temp.xori;
				output[count][1] = temp.yori;
				output[count][2] = temp.zori;
				count++;
			}
			result = this->getNextSensor(&temp);
		}
		return true;
	default:
		return false;
	}

}
