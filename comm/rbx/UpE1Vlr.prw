#Include "Protheus.ch"  
#Include "TOTVS.ch"    
#Include "REPORT.ch"   
#Include "TBICONN.CH"  
#include "Topconn.ch"  
#include "PRTOPDEF.ch"   

/*---------------------------------------------------------------------*
| Func:  JobUpdE1Vlr()                                                 |
| Autores: Eduardo Paranhos                                            |
| Data:  03/03/2026                                                    |
| Desc:  Respons�vel por atualizar E1_VLR baseado na FT_VALCONT quando |
| item for igual a 01                                                  |
| esse campo vazio.                                                    |
| Obs.:                                                                |
*---------------------------------------------------------------------*/


User Function JobUpdE1Vlr()

Local cSqlE1    := ""
Local cQryUpd    := ""
Local cAliasUpd    := GetNextAlias()
Local dDataIni    := FirstDate(Date())

    cQryUpd := "  SELECT FT_ITEM, FT_NFISCAL, FT_FILIAL, FT_ENTRADA, FT_EMISSAO, FT_CLIEFOR, FT_VALCONT, FT_BASEICM,  E1_VALOR, E1_VLCRUZ, E1_SALDO, E1_BASCOM1 " + CRLF
    cQryUpd += "  FROM " + RetSqlName("SFT") + " SFT " + CRLF
    cQryUpd += "  INNER JOIN SE1100 SE1 ON E1_NUM = FT_NFISCAL AND E1_CLIENTE = FT_CLIEFOR AND E1_VALOR <> FT_VALCONT AND E1_PREFIXO = FT_FILIAL" + CRLF
    cQryUpd += "  WHERE FT_ITEM = '01' AND FT_EMISSAO >= '" + DToS(dDataIni) + "' AND E1_NATUREZ = 'RBX21'" + CRLF
    cQryUpd += "  AND SFT.D_E_L_E_T_ = '' AND SE1.D_E_L_E_T_ = ' '   " + CRLF

    cQryUpd := ChangeQuery(cQryUpd)
    DBUseArea(.T.,'TOPCONN',TcGenQry(,,cQryUpd),cAliasUpd,.T.,.T.)

    While (cAliasUpd) ->(!Eof()) 

                cSqlE1:=" Update "+RetsqlName('SE1')
                cSqlE1+=" Set E1_VALOR = '"+ cValToChar((cAliasUpd)->FT_VALCONT) + "',"
                cSqlE1+= "E1_SALDO = '" + cValToChar((cAliasUpd)->FT_VALCONT) + "', " + CRLF
				cSqlE1+= "E1_VLCRUZ = '" + cValToChar((cAliasUpd)->FT_VALCONT) + "', " + CRLF
                cSqlE1+= "E1_BASCOM1 = '" + cValToChar((cAliasUpd)->FT_VALCONT) + "'" + CRLF
                cSqlE1+=" FROM SE1100 SE1" + CRLF
                cSqlE1+=" INNER JOIN SFT100 SFT ON E1_NUM = FT_NFISCAL AND E1_CLIENTE = FT_CLIEFOR AND E1_VALOR <> FT_VALCONT AND E1_PREFIXO = FT_FILIAL" + CRLF
                cSqlE1+=" WHERE SFT.D_E_L_E_T_ = '' AND SE1.D_E_L_E_T_ = ' '  AND SFT.FT_FILIAL = '"+ (cAliasUpd)->FT_FILIAL + "' AND FT_ITEM = '01' AND FT_EMISSAO >= '" + DToS(dDataIni) + "' AND E1_NATUREZ = 'RBX21'  AND SFT.FT_NFISCAL = '"+ (cAliasUpd)->FT_NFISCAL + "'  " + CRLF  
                TcSqlExec(cSqlE1)
    
        (cAliasUpd) ->(DbSkip()) 

    EndDo

(cAliasUpd)-> (dbCloseArea())   


    cQryUpd := "  SELECT FT_ITEM, FT_NFISCAL, FT_FILIAL, FT_ENTRADA, FT_EMISSAO, FT_CLIEFOR, FT_ALIQICM,FT_VALCONT,FT_BASEICM,FT_VALICM,F3_ALIQICM,F3_VALCONT,F3_BASEICM,F3_VALICM " + CRLF
    cQryUpd += "  FROM " + RetSqlName("SFT") + " SFT " + CRLF
    cQryUpd += "  INNER JOIN  SF3100 SF3 ON F3_NFISCAL = FT_NFISCAL AND F3_CLIEFOR = FT_CLIEFOR AND F3_BASEICM <> FT_BASEICM AND F3_SERIE = FT_FILIAL" + CRLF
    cQryUpd += "  WHERE FT_ITEM = '01' AND FT_EMISSAO >= '" + DToS(dDataIni) + "' AND F3_ESPECIE = 'NFCOM'  AND SFT.D_E_L_E_T_ = '' AND SF3.D_E_L_E_T_ = ' ' " + CRLF

    cQryUpd := ChangeQuery(cQryUpd)
    DBUseArea(.T.,'TOPCONN',TcGenQry(,,cQryUpd),cAliasUpd,.T.,.T.)

    While (cAliasUpd) ->(!Eof()) 

                cSqlE1:=" Update "+RetsqlName('SF3')
                cSqlE1+=" Set F3_VALCONT = '"+ cValToChar((cAliasUpd)->FT_VALCONT) + "',"
                cSqlE1+= "F3_ALIQICM = '" + cValToChar((cAliasUpd)->FT_ALIQICM) + "', " + CRLF
				cSqlE1+= "F3_BASEICM = '" + cValToChar((cAliasUpd)->FT_BASEICM) + "', " + CRLF
                cSqlE1+= "F3_VALICM = '" + cValToChar((cAliasUpd)->FT_VALICM) + "'" + CRLF
                cSqlE1+=" FROM SF3100 SF3" + CRLF
                cSqlE1+=" INNER JOIN SFT100 SFT ON F3_NFISCAL = FT_NFISCAL AND F3_CLIEFOR = FT_CLIEFOR AND F3_BASEICM <> FT_BASEICM AND F3_SERIE = FT_FILIAL" + CRLF
                cSqlE1+=" WHERE FT_ITEM = '01' AND FT_EMISSAO >= '" + DToS(dDataIni) + "' AND F3_ESPECIE = 'NFCOM'  AND SFT.D_E_L_E_T_ = '' AND SF3.D_E_L_E_T_ = ' '  AND SFT.FT_FILIAL = '"+ (cAliasUpd)->FT_FILIAL + "'  AND SFT.FT_NFISCAL = '"+ (cAliasUpd)->FT_NFISCAL + "'  " + CRLF  
                TcSqlExec(cSqlE1)
    
        (cAliasUpd) ->(DbSkip()) 

    EndDo

(cAliasUpd)-> (dbCloseArea())   

		//UPDATE Criado parra ajustar valores da SF2 com base na SF3.
		cSqlE1 := " UPDATE " + RetSqlName('SF2') + " SF2 SET" + CRLF
		cSqlE1 += "     F2_VALBRUT = SF3.F3_VALCONT," + CRLF
		cSqlE1 += "     F2_VALFAT  = SF3.F3_VALCONT," + CRLF
		cSqlE1 += "     F2_VALMERC = SF3.F3_VALCONT," + CRLF
		cSqlE1 += "     F2_VALICM  = SF3.F3_VALICM," + CRLF
		cSqlE1 += "     F2_BASEICM = SF3.F3_BASEICM" + CRLF
		cSqlE1 += " FROM " + RetSqlName('SF2') + " SF2" + CRLF
		cSqlE1 += " INNER JOIN " + RetSqlName('SF3') + " SF3" + CRLF
		cSqlE1 += "     ON SF3.F3_FILIAL  = SF2.F2_FILIAL" + CRLF
		cSqlE1 += "    AND SF3.F3_NFISCAL = SF2.F2_DOC" + CRLF
		cSqlE1 += "    AND SF3.F3_SERIE   = SF2.F2_SERIE" + CRLF
		cSqlE1 += "    AND SF3.F3_CLIEFOR = SF2.F2_CLIENTE" + CRLF
		cSqlE1 += " WHERE SF3.F3_VALCONT <> SF2.F2_VALBRUT" + CRLF
		cSqlE1 += "   AND SF3.F3_CFO = '5301'" + CRLF
		cSqlE1 += "   AND SF3.F3_ENTRADA >= '" + DToS(dDataIni) + "'" + CRLF
		cSqlE1 += "   AND SF3.D_E_L_E_T_ = ''" + CRLF
		cSqlE1 += "   AND SF2.D_E_L_E_T_ = ''" + CRLF
		TcSqlExec(cSqlE1)


Return




