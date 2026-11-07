// lcDataBufferFile.cpp: implementation of the lcDataBufferFile class.
//
//////////////////////////////////////////////////////////////////////

#include "lcDataBufferFile.h"
#include "lc_io.h"
#include <string.h>

//////////////////////////////////////////////////////////////////////
// Construction/Destruction
//////////////////////////////////////////////////////////////////////

lcDataBufferFile::lcDataBufferFile()
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

	dborder = 0;
	
	epochs = NULL;
	epochsBL = NULL;


	for(int i=0; i<100;i++) memset(sigFileNames[i],0,256);
}

lcDataBufferFile::~lcDataBufferFile()
{
	reset();
}

lcDataBufferFile::lcDataBufferFile(int nfn, char *fn, int ne, int nc, int ns, int tc, int neBL, int nsBL,int dataBorder)
{
	if( (!ne) || (!nc) || (!ns) ) {
		lcDataBufferFile();
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

	strcpy(sigFileNames[nfn],fn);

	dborder = dataBorder;

	initialize();
}

void lcDataBufferFile::initialize()
{
	if( (!nchans) || (!nepochs) || (!nsmpl) ) {
		error = DBE_NO_DATA;
		return;
	}

	int j;
	
	if(!epochs){
		epochs = new lcDBsection*[ntimes];
		for(int i=0;i<ntimes; i++) 
		{
			epochs[i] = new lcDBsection[nepochs];
			for(j = 0;j<nepochs;j++) epochs[i][j].fileIndex = -1;
		}
	}

	if(nepochsBL && !epochsBL){
		epochsBL = new lcDBsection[nepochsBL];
		for(j = 0;j<nepochs;j++) epochsBL[j].fileIndex = -1;
	}


	error = DBE_NONE;
}

void lcDataBufferFile::initialize(int nfn, char *fn, int ne, int nc, int ns, int tc,int neBL, int nsBL,int dataBorder )
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

	strcpy(sigFileNames[nfn],fn);

	dborder = dataBorder;
	initialize();
}

void lcDataBufferFile::initialize(int ne, int nc, int ns, int tc,int neBL, int nsBL,int dataBorder)
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

	dborder = dataBorder;

	initialize();
}

void lcDataBufferFile::initialize(int nfn, char *fn)
{

	strcpy(sigFileNames[nfn],fn);

	initialize();
}

void lcDataBufferFile::initializeBL(int nfn, char *fn)
{

	strcpy(blFileNames[nfn],fn);

	initialize();
}

int lcDataBufferFile::getChannels()
{
	return nchans;
}

int lcDataBufferFile::getEpochs()
{
	return nepochs;
}

int lcDataBufferFile::getEpochsBL()
{
	return nepochsBL;
}

int lcDataBufferFile::getPoints()
{
	return nsmpl;
}

int lcDataBufferFile::getPointsBL()
{
	return nsmplBL;
}

void lcDataBufferFile::reset()
{
	freeData();
	freeBuffer();
	
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

	for(int i=0; i<100;i++) memset(sigFileNames[i],0,256);

	dborder = 0;

	epochs = NULL;
	epochsBL = NULL;


}

bool lcDataBufferFile::isInitialized()
{
	if(epochs!=NULL ) return true; else return false;
}

void lcDataBufferFile::setValue(int e, int c, int s, double value, int t)
{
	error = DBE_NO_DATA;
	if(data==NULL) return;
	if(t<0 || t>ntimes) return;
	if(e<0 || e>nepochs) return;
	if(c<0 || c>nchans) return;
	if(s<0 || s>nsmpl) return;

//	(((data[t])[e])[c])[s] = value;
	
	error = DBE_NONE;
}

void lcDataBufferFile::setValueBL(int e, int c, int s, double value)
{
	error = DBE_NO_BASELINE;
	if(dataBL==NULL) return;
	if(e<0 || e>nepochsBL) return;
	if(c<0 || c>nchans) return;
	if(s<0 || s>nsmplBL) return;

//	((dataBL[e])[c])[s] = value;
	error = DBE_NONE;
}

void lcDataBufferFile::setValue(int e, int c, double *timeline, int t)
{
	error = DBE_NO_DATA;
	if(data==NULL) return;
	if(t<0 || t>ntimes) return;
	if(e<0 || e>nepochs) return;
	if(c<0 || c>nchans) return;

//	memcpy(((data[t])[e])[c],timeline,nsmpl*sizeof(double));
	error = DBE_NONE;
}

void lcDataBufferFile::setValueBL(int e, int c, double *timeline)
{
	error = DBE_NO_BASELINE;
	if(dataBL==NULL) return;
	if(e<0 || e>nepochsBL) return;
	if(c<0 || c>nchans) return;

//	memcpy((dataBL[e])[c],timeline,nsmplBL*sizeof(double));
	error = DBE_NONE;
}

void lcDataBufferFile::setValue(int e, double **timematrix, int t)
{
	error = DBE_NO_DATA;
	if(data==NULL) return;
	if(t<0 || t>ntimes) return;
	if(e<0 || e>nepochs) return;

//	memcpy((data[t])[e],timematrix,nchans*nsmpl*sizeof(double));
	error = DBE_NONE;
}

void lcDataBufferFile::setValueBL(int e, double **timematrix)
{
	error = DBE_NO_BASELINE;
	if(dataBL==NULL) return;
	if(e<0 || e>nepochsBL) return;

//	memcpy(dataBL[e],timematrix,nchans*nsmplBL*sizeof(double));
	error = DBE_NONE;
}

void lcDataBufferFile::setStartData(int start)
{
	startData = start;
}

int lcDataBufferFile::getStartData()
{
	return this->startData;
}

double lcDataBufferFile::getValue(int e, int c, int s, int t)
{
	error = DBE_NO_DATA;
	if(data==NULL) return 0;
	if(t<0 || t>ntimes) return 0;
	if(e<0 || e>nepochs) return 0;
	if(c<0 || c>nchans) return 0;
	if(s<0 || s>nsmpl) return 0;

	error = DBE_NONE;
//	return (((data[t])[e])[c])[s];
	return 0;
}

double lcDataBufferFile::getValueBL(int e, int c, int s)
{
	error = DBE_NO_BASELINE;
	if(dataBL==NULL) return 0;
	if(e<0 || e>nepochsBL) return 0;
	if(c<0 || c>nchans) return 0;
	if(s<0 || s>nsmplBL) return 0;

	error = DBE_NONE;
//	return ((dataBL[e])[c])[s];
	return 0;
}

double ** lcDataBufferFile::getValue(int e, int t, double **res)
{
	error = DBE_NO_DATA;
	if(t<0 || t>ntimes) return 0;
	if(e<0 || e>nepochs) return 0;

	if(epochs[t][e].fileIndex<0) return NULL;

	error = DBE_NONE;
	if(!data){
		currentFile = epochs[t][e].fileIndex;
		if(!load(currentFile)) return NULL;
	}else{
		if(currentFile != epochs[t][e].fileIndex){
			currentFile = epochs[t][e].fileIndex;
			if(!load(currentFile)) return NULL;
		}
	}


	for(int i=0;i<nchans;i++) memcpy(res[i],&(data[i][epochs[t][e].index]),nsmpl*sizeof(double));

	return res;
}

double ** lcDataBufferFile::getValueBL(int e)
{
	error = DBE_NO_BASELINE;
	if(dataBL==NULL) return 0;
	if(e<0 || e>nepochsBL) return 0;

	error = DBE_NONE;
//	return dataBL[e];
	return 0;
}

void lcDataBufferFile::reselectChannels(lcSensorData *sd)
{
	
	/*
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

*/
}

void lcDataBufferFile::setAbsSubSet(int a, int b)
{
	a -= this->offsetFromTrigger;

	this->subset[0] = a;
	this->subset[1] = a+b;
}

void lcDataBufferFile::setAbsSubSetBL(int a, int b)
{
	a -= this->offsetDataBL;

	this->subsetBL[0] = a;
	this->subsetBL[1] = a+b;
}

void lcDataBufferFile::setRelSubSet(int a, int b)
{
	this->subset[0] = a;
	this->subset[1] = a+b;
}

void lcDataBufferFile::setRelSubSetBL(int a, int b)
{
	this->subsetBL[0] = a;
	this->subsetBL[1] = a+b;
}

int lcDataBufferFile::getSubSet(int index)
{
	if(!(subset[0] + subset[1])) return -1;
	return subset[index];
}

int lcDataBufferFile::getSubSetBL(int index)
{
	if(!(subsetBL[0] + subsetBL[1])) {
		error = DBE_SUBSET_EMPTY;
		return -1;
	}
	error = DBE_NONE;
	return subsetBL[index];
}

int lcDataBufferFile::getSubSetSpan()
{
	return (subset[1] - subset[0]);
}

int lcDataBufferFile::getSubSetSpanBL()
{
	return (subsetBL[1] - subsetBL[0]);
}

void lcDataBufferFile::freeData()
{

	if( (!nchans) || (!nepochs) || (!nsmpl) ) return;


	if(epochs) {
		for(int i=0;i<ntimes;i++) delete epochs[i];
		delete[] epochs;
		epochs = NULL;
	}

	if(epochsBL) delete[] epochsBL;
	epochsBL = NULL;


}

lcDataBufferFile::lcDBerrorType lcDataBufferFile::getError()
{
	return error;
}

int lcDataBufferFile::getTimeInstants()
{
	return ntimes;
}

int lcDataBufferFile::getTimeResolution()
{
	return timeres;
}

void lcDataBufferFile::setTimeResolution(int tr)
{
	timeres = tr;
}

double *** lcDataBufferFile::getAllEpochs(int t)
{
//	return this->data[t];
	return 0;
}

double *** lcDataBufferFile::getAllEpochsBL()
{
//	return this->dataBL;
	return 0;
}

void lcDataBufferFile::setEpoch(int inst, int ne, int index, int findex, int offset)
{
	epochs[inst][ne].index = index;
	epochs[inst][ne].fileIndex = findex;
	epochs[inst][ne].offset = offset;
}

void lcDataBufferFile::setEpochBL(int ne, int index, int findex, int offset)
{
	epochsBL[ne].index = index;
	epochsBL[ne].fileIndex = findex;
	epochsBL[ne].offset = offset;
}


bool lcDataBufferFile::load(int nfile)
{
	freeBuffer();

	lc_IO::loadBinary((double**)NULL,sigFileNames[nfile],0,bufferSize);

	data = new double*[bufferSize[0]];
	for(int i=0;i<bufferSize[0];i++)  data[i] = new double[bufferSize[1]];

	return(!lc_IO::loadBinary(data,sigFileNames[nfile]));

}

void lcDataBufferFile::freeBuffer()
{
	if(data){
		for(int i=0;i<bufferSize[0];i++) delete[] data[i];
		delete[] data;

		data = NULL;
	}
}


lcDataBufferFile::lcDBsection lcDataBufferFile::getEpochParameters(int e, int t){
	return epochs[t][e];
}

lcDataBufferFile::lcDBsection lcDataBufferFile::getEpochBLParameters(int e, int t){
	return epochs[t][e];
}

