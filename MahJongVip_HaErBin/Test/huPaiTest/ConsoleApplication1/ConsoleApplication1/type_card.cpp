#include "stdafx.h"
#include "type_card.h"
#include <algorithm>


TMJMingPaiItem::TMJMingPaiItem()
{
	rMJAction = mjaError;
}

TMJMingPaiItem::TMJMingPaiItem(int place, int lastPlace, int lastCardId, TMJActionName mjAction, int cardId)
{
	rPlace = place;
	rLastPlace = lastPlace;
	rLastCardId = lastCardId;
	rMJAction = mjAction;
	rAryData.push_back(cardId);
}

TMJMingPaiItem::TMJMingPaiItem(int place, int lastPlace, int lastCardId, TMJActionName mjAction, vector<int>& dataVector)
{
	rPlace = place;
	rLastPlace = lastPlace;
	rLastCardId = lastCardId;
	rMJAction = mjAction;
	rAryData.resize(dataVector.size());
	copy(dataVector.begin(), dataVector.end(), rAryData.begin());
}

TMJMingPaiItem::TMJMingPaiItem(const TMJMingPaiItem& other)
{
	rAryData.resize(other.rAryData.size());
	copy(other.rAryData.begin(), other.rAryData.end(), rAryData.begin());
	rPlace = other.rPlace;
	rMJAction = other.rMJAction;
	rLastCardId = other.rLastCardId;
	rLastPlace = other.rLastPlace;
}

TMJMingPaiItem::~TMJMingPaiItem()
{

}

