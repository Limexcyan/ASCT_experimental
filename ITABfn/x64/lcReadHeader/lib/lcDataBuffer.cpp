// lcDataBuffer.cpp: implementation of the lcDataBuffer class.
//
//////////////////////////////////////////////////////////////////////

#include "lcDataBuffer.h"
#include <string.h>

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

lcDataBuffer::lcDataBuffer()
{
	nchans = 0;
	nepochs = 0;
	ntimes = 0;
	timeres = 0;

	nsmpl = 0;
	subset[0] = 0;
	subset[1] = 0;
	data = NULL;

	nepochsBL = 0;
	nsmplBL = 0;
	subsetBL[0] = 0;
	subsetBL[1] = 0;
	dataBL = NULL;
}

lcDataBuffer::~lcDataBuffer()
{
	reset();
}

lcDataBuffer::lcDataBuffer(int ne, int nc, int ns, int tc, int neBL, int nsBL)
{
	if( (!ne) || (!nc) || (!ns) ) {
		lcDataBuffer();
		error = DBE_NO_DATA;
		return;
	}

	nchans = nc;
	nepochs = ne;
	ntimes = tc;

	nsmpl = ns;
	offsetFromTrigger = 0;
	subset[0] = 0;
	subset[1] = 0;

	nepochsBL = neBL;
	nsmplBL = nsBL;
	offsetDataBL = 0;
	subsetBL[0] = 0;
	subsetBL[1] = 0;

	data = NULL;
	dataBL = NULL;

	initialize();
}

void lcDataBuffer::initialize()
{
	if( (!nchans) || (!nepochs) || (!nsmpl) ) {
		error = DBE_NO_DATA;
		return;
	}


	data = new double***[ntimes];
	if(!data) {
		error = DBE_MEMORY;
		data = NULL;
		return;
	}
	for(int k=0;k<ntimes;k++){
		data[k] = new double**[nepochs];
		if(!data[k]){
			error = DBE_MEMORY;
			for(--k;k>0;k--) delete[] data[k];
			delete[] data;
			data = NULL;
			return;
		}
		for(int i=0; i<nepochs; i++){
			(data[k])[i] = new double*[nchans];
			if(!data[k][i]){
				error = DBE_MEMORY;
				for(--i;i>0;i--) delete[] data[k][i];
				delete[] data[k];
				for(--k;k>0;k--) {
					for(i=(nepochs-1);i>0;i--) delete[] data[k][i];
					delete[] data[k];
				}
				delete[] data;
				data = NULL;
				return;
			}
			for(int j=0; j<nchans; j++) {
				((data[k])[i])[j] = new double[nsmpl];
				if(!data[k][i][j]){
					error = DBE_MEMORY;
					for(--j;j>0;j--) delete[] data[k][i][j];
					delete[] data[k][i];
					for(--i;i>0;i--) {
						for(j=nchans-1;j>0;j--) delete[] data[k][i][j];
						delete[] data[k][i];					
					}
					delete[] data[k];
					for(--k;k>0;k--) {
						for(i=(nepochs-1);i>0;i--) {
							for(j=nchans-1;j>0;j--) delete[] data[k][i][j];							
							delete[] data[k][i];
						}
						delete[] data[k];
					}
					delete[] data;
					data = NULL;
					return;
				}

			}
		}
	}

	if( nsmplBL ){
		dataBL = new double**[nepochsBL];
		if(!dataBL) {
			error = DBE_MEMORY;
			dataBL = NULL;
			return;
		}
		for(int i=0; i<nepochsBL; i++){
			dataBL[i] = new double*[nchans];
			if(!dataBL[i]){
				error = DBE_MEMORY;
				for(--i;i>0;i--) delete[] dataBL[i];
				delete[] dataBL;
				dataBL = NULL;
				return;
			}
			for(int j=0; j<nchans; j++) {
				(dataBL[i])[j] = new double[nsmplBL];
				if(!dataBL[i][j]){
					error = DBE_MEMORY;
					for(--j;j>0;j--) delete[] dataBL[i][j];
					delete[] data[i];
					for(--i;i>0;i--) {
						for(j=nchans-1;j>0;j--) delete dataBL[i][j];
						delete[] dataBL[i];
					}
					delete[] dataBL;
					dataBL = NULL;
					return;
				}
			}
		}
	}

	error = DBE_NONE;
}

void lcDataBuffer::initialize(int ne, int nc, int ns, int tc,int neBL, int nsBL)
{
	if( (!ne) || (!nc) || (!ns) ) {
		error = DBE_NO_DATA;
		return;
	}

	reset();

	nchans = nc;
	nepochs = ne;
	nepochsBL = neBL;
	nsmpl = ns;
	nsmplBL = nsBL;
	ntimes = tc;

	initialize();
}

int lcDataBuffer::getChannels()
{
	return nchans;
}

int lcDataBuffer::getEpochs()
{
	return nepochs;
}

int lcDataBuffer::getEpochsBL()
{
	return nepochsBL;
}

int lcDataBuffer::getPoints()
{
	return nsmpl;
}

int lcDataBuffer::getPointsBL()
{
	return nsmplBL;
}

void lcDataBuffer::reset()
{
	freeData();
	
	nchans = 0;
	nepochs = 0;
	nepochsBL = 0;
	ntimes = 0;
	timeres = 0;

	nsmpl = 0;
	subset[0] = 0;
	subset[1] = 0;

	nsmplBL = 0;
	subsetBL[0] = 0;
	subsetBL[1] = 0;

}

bool lcDataBuffer::isInitialized()
{
	if(data!=NULL) return true; else return false;
}

void lcDataBuffer::setValue(int e, int c, int s, double value, int t)
{
	error = DBE_NO_DATA;
	if(data==NULL) return;
	if(t<0 || t>ntimes) return;
	if(e<0 || e>nepochs) return;
	if(c<0 || c>nchans) return;
	if(s<0 || s>nsmpl) return;

	(((data[t])[e])[c])[s] = value;
	
	error = DBE_NONE;
}

void lcDataBuffer::setValueBL(int e, int c, int s, double value)
{
	error = DBE_NO_BASELINE;
	if(dataBL==NULL) return;
	if(e<0 || e>nepochsBL) return;
	if(c<0 || c>nchans) return;
	if(s<0 || s>nsmplBL) return;

	((dataBL[e])[c])[s] = value;
	error = DBE_NONE;
}

void lcDataBuffer::setValue(int e, int c, double *timeline, int t)
{
	error = DBE_NO_DATA;
	if(data==NULL) return;
	if(t<0 || t>ntimes) return;
	if(e<0 || e>nepochs) return;
	if(c<0 || c>nchans) return;

	memcpy(((data[t])[e])[c],timeline,nsmpl*sizeof(double));
	error = DBE_NONE;
}

void lcDataBuffer::setValueBL(int e, int c, double *timeline)
{
	error = DBE_NO_BASELINE;
	if(dataBL==NULL) return;
	if(e<0 || e>nepochsBL) return;
	if(c<0 || c>nchans) return;

	memcpy((dataBL[e])[c],timeline,nsmplBL*sizeof(double));
	error = DBE_NONE;
}

void lcDataBuffer::setValue(int e, double **timematrix, int t)
{
	error = DBE_NO_DATA;
	if(data==NULL) return;
	if(t<0 || t>ntimes) return;
	if(e<0 || e>nepochs) return;

	memcpy((data[t])[e],timematrix,nchans*nsmpl*sizeof(double));
	error = DBE_NONE;
}

void lcDataBuffer::setValueBL(int e, double **timematrix)
{
	error = DBE_NO_BASELINE;
	if(dataBL==NULL) return;
	if(e<0 || e>nepochsBL) return;

	memcpy(dataBL[e],timematrix,nchans*nsmplBL*sizeof(double));
	error = DBE_NONE;
}

void lcDataBuffer::setStartData(int start)
{
	startData = start;
}

int lcDataBuffer::getStartData()
{
	return this->startData;
}

double lcDataBuffer::getValue(int e, int c, int s, int t)
{
	error = DBE_NO_DATA;
	if(data==NULL) return 0;
	if(t<0 || t>ntimes) return 0;
	if(e<0 || e>nepochs) return 0;
	if(c<0 || c>nchans) return 0;
	if(s<0 || s>nsmpl) return 0;

	error = DBE_NONE;
	return (((data[t])[e])[c])[s];
}

double lcDataBuffer::getValueBL(int e, int c, int s)
{
	error = DBE_NO_BASELINE;
	if(dataBL==NULL) return 0;
	if(e<0 || e>nepochsBL) return 0;
	if(c<0 || c>nchans) return 0;
	if(s<0 || s>nsmplBL) return 0;

	error = DBE_NONE;
	return ((dataBL[e])[c])[s];
}

double ** lcDataBuffer::getValue(int e, int t)
{
	error = DBE_NO_DATA;
	if(data==NULL) return 0;
	if(t<0 || t>ntimes) return 0;
	if(e<0 || e>nepochs) return 0;

	error = DBE_NONE;
	return (data[t])[e];
}

double ** lcDataBuffer::getValueBL(int e)
{
	error = DBE_NO_BASELINE;
	if(dataBL==NULL) return 0;
	if(e<0 || e>nepochsBL) return 0;

	error = DBE_NONE;
	return dataBL[e];
}

void lcDataBuffer::reselectChannels(lcSensorData *sd)
{
	int bad = sd->getNumberOfBadSensors();
	int good = sd->getNumberOfGoodSensors();
	int tot = sd->getNumberOfSensors();
	int virt = sd->getNumberOfVirtualSensors();

	int i,j,k;

	lcSensorData::PARAMS p;


	// allocate temporary buffer for data
	
	double ****temp, ***tempBL;
	temp = new double***[ntimes];
	for(k=0;k<ntimes;k++){
		temp[k] = new double**[nepochs];
		for(i=0; i<nepochs; i++){
			(temp[k])[i] = new double*[good];
			for(j=0; j<good; j++) {
				((temp[k])[i])[j] = new double[nsmpl];
			}
		}
	}

	if(nsmplBL){
		tempBL = new double**[nepochsBL];
		for(i=0; i<nepochsBL; i++){
			tempBL[i] = new double*[good];
			for(j=0; j<good; j++) {
				(tempBL[i])[j] = new double[nsmplBL];
			}
		}
	}


	int count = 0;
	bool ch[640], chMH[640];
	memset(ch,0,sizeof(bool)*640);	 // selezione canali: false: rotto, true: buono
	memset(chMH,1,sizeof(bool)*640); // selezione dei canali da master header: false: rotto, true: buono

	// select channels by flags
	bool disp = sd->getFirstSensor(&p);
	while(disp){
		if(p.flag != 1){
			if(p.flag == 0) ch[p.number] = true;
			count++;
		}else  chMH[p.number] = false;

		disp = sd->getNextSensor(&p);
	}

	// select data by channels
	int m;
	for(j=0;j<nepochs;j++){
		k=0;m = 0;
		for(i=0;i<tot;i++){
			if(ch[i] && chMH[i]){
				memcpy((temp[j])[k],(data[j])[m],sizeof(double)*nsmpl);
				k++;
			}
			if(chMH[i]) m++;
		}
	}

	if(nsmplBL){
	for(j=0;j<nepochsBL;j++){
		k=0;m = 0;
		for(i=0;i<tot;i++){
			if(ch[i] && chMH[i]){
				memcpy((tempBL[j])[k],(dataBL[j])[m],sizeof(double)*nsmplBL);
				k++;
			}
			if(chMH[i]) m++;
		}
	}
	}

	// reset data
	this->freeData();


	nchans = good;

	// fill new selected data
	data = new double***[ntimes];
	for(k=0;k<ntimes;k++){
		data[k] = new double**[nepochs];
		for(i=0; i<nepochs; i++){
			(data[k])[i] = new double*[nchans];
			for(j=0; j<nchans; j++) {
				((data[k])[i])[j] = new double[nsmpl];
				memcpy(((data[k])[i])[j],((temp[k])[i])[j],sizeof(double)*nsmpl);
			}
		}
	}

	if(nsmplBL){
		dataBL = new double**[nepochsBL];
		for(i=0; i<nepochsBL; i++){
			dataBL[i] = new double*[nchans];
			for(j=0; j<nchans; j++) {
				(dataBL[i])[j] = new double[nsmplBL];
				memcpy((dataBL[i])[j],(tempBL[i])[j],sizeof(double)*nsmplBL);
			}
		}
	}

	// free temporary buffer
	for(k=0;k<ntimes;k++){
		for(i=0; i<nepochs; i++){
			for(j=0; j<nchans; j++) delete[] ((temp[k])[i])[j];
			delete[] (temp[k])[i];
		}
		delete[] temp[k];
	}
	delete[] temp;

	if(nsmplBL){
		for(i=0; i<nepochsBL; i++){
			for(j=0; j<nchans; j++) delete[] (tempBL[i])[j];
			delete[] tempBL[i];
		}
		delete[] tempBL;
	}


}

void lcDataBuffer::setAbsSubSet(int a, int b)
{
	a -= this->offsetFromTrigger;

	this->subset[0] = a;
	this->subset[1] = a+b;
}

void lcDataBuffer::setAbsSubSetBL(int a, int b)
{
	a -= this->offsetDataBL;

	this->subsetBL[0] = a;
	this->subsetBL[1] = a+b;
}

void lcDataBuffer::setRelSubSet(int a, int b)
{
	this->subset[0] = a;
	this->subset[1] = a+b;
}

void lcDataBuffer::setRelSubSetBL(int a, int b)
{
	this->subsetBL[0] = a;
	this->subsetBL[1] = a+b;
}

int lcDataBuffer::getSubSet(int index)
{
	if(!(subset[0] + subset[1])) return -1;
	return subset[index];
}

int lcDataBuffer::getSubSetBL(int index)
{
	if(!(subsetBL[0] + subsetBL[1])) {
		error = DBE_SUBSET_EMPTY;
		return -1;
	}
	error = DBE_NONE;
	return subsetBL[index];
}

int lcDataBuffer::getSubSetSpan()
{
	return (subset[1] - subset[0]);
}

int lcDataBuffer::getSubSetSpanBL()
{
	return (subsetBL[1] - subsetBL[0]);
}

void lcDataBuffer::freeData()
{

	if( (!nchans) || (!nepochs) || (!nsmpl) ) return;

	if(data){
		for(int k=0;k<ntimes;k++){
			for(int i=0; i<nepochs; i++){
				for(int j=0; j<nchans; j++) delete[] ((data[k])[i])[j];
				delete[] (data[k])[i];
			}
			delete[] data[k];
		}
		delete[] data;
	}

	if(nsmplBL){
		if(dataBL){
			for(int i=0; i<nepochsBL; i++){
				for(int j=0; j<nchans; j++) delete[] (dataBL[i])[j];
				delete[] dataBL[i];
			}
			delete[] dataBL;
		}
	}

	data = NULL;
	dataBL = NULL;

}

lcDataBuffer::lcDBerrorType lcDataBuffer::getError()
{
	return error;
}

int lcDataBuffer::getTimeInstants()
{
	return ntimes;
}

int lcDataBuffer::getTimeResolution()
{
	return timeres;
}

void lcDataBuffer::setTimeResolution(int tr)
{
	timeres = tr;
}

double *** lcDataBuffer::getAllEpochs(int t)
{
	return this->data[t];
}

double *** lcDataBuffer::getAllEpochsBL()
{
	return this->dataBL;
}
