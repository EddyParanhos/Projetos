#include 'protheus.ch'
#include 'parmtype.ch'
#INCLUDE "RWMAKE.CH"


/*---------------------------------------------------------------------*
| Func:  MATUCOMP()                                                   |
| Autor: Edmar Paranhos                                               |
| Data:  18/10/2018                                                   |
| Desc:  Alimenta tabelas de complementos (SFX).                      |
| Obs.: *MV_ATUCOMP = T         				                      |
*---------------------------------------------------------------------*/


User Function MATUCOMP()

	Local cCodIt := "" //Codigo de produto de exemplo - ajustar conforme necessidade
	Local cDataM := ""
	Local cDataA := ""
	Local cData1 := ""
	

	cEntSai := ParamIXB[1]
	cSerie  := ParamIXB[2]
	cDoc    := ParamIXB[3]
	cCliefor:= ParamIXB[4]
	cLoja   := ParamIXB[5]


	IIf(inclui,'',POSICIONE("SD2",3,XFILIAL("SD2") + cDoc,"D2_COD"))
	cCodIt := Alltrim(SD2->D2_COD)

	If cEntSai == "S" .And. Alltrim(cCodIt) == "COD_EXEMPLO"

		dbselectarea("SC6")
		dbsetorder(4) //C6_FILIAL, C6_NOTA, C6_SERIE
		dbseek(xFilial("SC6")+cDoc+cSerie)

		If SC6->(DbSeek(xFilial("SC6")+cDoc+cSerie))
			While !SC6-> (Eof()) .and. SC6->C6_NOTA == cDoc .and. SC6->C6_SERIE == cSerie

				RecLock("SFX",.T.)

				SFX->FX_FILIAL	:= xFilial("SFX")
				SFX->FX_TIPOMOV	:= "S"
				SFX->FX_DOC	    := cDoc
				SFX->FX_SERIE	:= cSerie
				SFX->FX_ESPECIE	:= "NTST"
				SFX->FX_CLIFOR	:= cClieFor
				SFX->FX_LOJA	:= cLoja
				SFX->FX_ITEM    := SD2->D2_ITEM
				SFX->FX_COD	    := SD2->D2_COD
				SFX->FX_TPCLASS	:= "00"			
				SFX->FX_CLASCON	:= "99"
				SFX->FX_CLASSIF	:= "99"			
				SFX->FX_VALTERC	:= SD2->D2_TOTAL
				SFX->FX_TIPOREC	:= "0"
				SFX->FX_RECEP	:= cClieFor			
				SFX->FX_LOJAREC	:= cLoja
				SFX->FX_TIPSERV	:= "0"
				SFX->FX_DTINI	:= SD2->D2_EMISSAO
				SFX->FX_DTFIM	:= SD2->D2_EMISSAO
                
                //09/04/2019 - Ajuste no campo Data da SFX para não ocorrer erro na validação do .txt
                
				cDataM := Month2Str(SD2->D2_EMISSAO) //Mês
				
				cDataA := Year2Str(SD2->D2_EMISSAO) // Ano
							
				cData1 := cDataM+cDataA //MMAAAA
				
				SFX->FX_PERFIS	:= cData1  

				SFX->FX_AREATER	:= "11"
				SFX->FX_TERMINA	:= "00000000" // Exemplo - ajustar conforme necessidade
				SFX->FX_TPASSIN	:= "1"			
				SFX->FX_GRPCLAS	:= "01"
				SFX->FX_CLASSIT	:= "599"
				SFX->FX_SDOC	:= cSerie


				SFX -> ( MsUnlock())

				SC6->(DbSkip())

			Enddo
		EndIf
	Endif

	If cEntSai == "S" .And. SD2->D2_VALICM <> 0 .And. SD2->D2_BASIMP5 <> 0 .And. SD2->D2_SERIE <> 'UNI'

		dbselectarea("SC6")
		dbsetorder(4) //C6_FILIAL, C6_NOTA, C6_SERIE
		dbseek(xFilial("SC6")+cDoc+cSerie)

		If SC6->(DbSeek(xFilial("SC6")+cDoc+cSerie))
			While !SC6->(Eof()) .and. SC6->C6_NOTA == cDoc .and. SC6->C6_SERIE == cSerie

				RecLock("CDG",.T.)

				dbSelectArea("CDG")
				//Gera Complemento para todos os itens da NF	
				CDG-> ( dbSetOrder(1))
				CDG->CDG_FILIAL	:= xFilial("CDG")
				CDG->CDG_TPMOV	:= cEntSai
				CDG->CDG_DOC	:= cDoc
				CDG->CDG_SERIE	:= cSerie
				CDG->CDG_CLIFOR	:= cClieFor
				CDG->CDG_LOJA	:= cLoja
				CDG->CDG_IFCOMP	:= "000001"
				CDG->CDG_ITEM	:= SC6->C6_ITEM
				CDG->CDG_PROCESS:= "0000000-00" // Exemplo - ajustar conforme necessidade
				CDG->CDG_TPPROC	:= "1"
				CDG->CDG_ITPROC	:= "00000001"
				CDG->CDG_SDOC	:= cSerie

				CDG-> ( MsUnlock())

				SC6-> ( DbSkip())

			Enddo
		EndIf
	Endif


	//Inclusao da regra CDT - Informações complementares.

	If cEntSai == "S" .And. SD2->D2_VALICM <> 0 .And. SD2->D2_BASIMP5 <> 0 .And. SD2->D2_SERIE <> 'UNI'

		dbselectarea("SC6")
		dbsetorder(4) //C6_FILIAL, C6_NOTA, C6_SERIE
		dbseek(xFilial("SC6")+cDoc+cSerie)

		If SC6->(DbSeek(xFilial("SC6")+cDoc+cSerie))

			//lExiste 	:= CDT->(dbSeek(xFilial("CDT")+cDoc+cSerie))

			//If lExiste
			//	RecLock("CDT",.F.)

			//Else                                       
			RecLock("CDT",.T.)

			dbSelectArea("CDT")
			CDT-> ( dbSetOrder(1))
			CDT->CDT_FILIAL	:= xFilial("CDT")	
			CDT->CDT_TPMOV	:= cEntSai	
			CDT->CDT_DOC	:= cDoc	
			CDT->CDT_SERIE	:= cSerie	
			CDT->CDT_CLIFOR	:= cClieFor	
			CDT->CDT_LOJA	:= cLoja								
			CDT->CDT_IFCOMP := "000001"

			CDT-> ( MsUnlock())

			SC6-> ( DbSkip())
		EndIf
	Endif 

Return
