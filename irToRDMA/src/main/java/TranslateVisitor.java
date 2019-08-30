
import java.util.ArrayList;
import java.util.List;
import java.util.Stack;

/**
 * Created by Andrei on 8/28/15.
 * Modified by Yuri 09/2019
 */
public class TranslateVisitor extends TLBaseVisitor<Object> {
    Stack<List<String>> actions_in_ifs;
    TranslateValue result;
    int currentNodeNumber;
    int currentProcNumber;
    int counter; /* unique id for each action */
    int if_context_counter;
    String lastActionName;
    StringBuffer simpleExpressionBuffer;


    public TranslateVisitor(TranslateValue value) {
        this.actions_in_ifs = new Stack<List<String>>();
        this.result = value;
        this.currentProcNumber = -1;
        this.counter = 0;
        this.simpleExpressionBuffer = new StringBuffer();
        this.if_context_counter = 0;
    }

    @Override
    public Object visitNode(TLParser.NodeContext ctx) {
        int nodeNumber = Integer.parseInt(ctx.Number().getText());
        this.currentNodeNumber = nodeNumber;

        appendVarToBuffer("n" + nodeNumber, result.Nodes);
        result.programBuffer.append("\n/* Node " + nodeNumber + " */\n");
        this.lastActionName = null;
        visitChildren(ctx);
        return null;
    }

    @Override
    public Object visitProcess(TLParser.ProcessContext ctx) {
        int procNumber = Integer.parseInt(ctx.Number().getText());
        this.currentProcNumber = procNumber;

        appendVarToBuffer("p" + procNumber, result.Processes);
        result.programBuffer.append("\n/* Process " + procNumber + " */\n");
        this.lastActionName = null;
        visitChildren(ctx);
        return null;
    }

    @Override
    public Object visitSharedDecl(TLParser.SharedDeclContext ctx) {
        for (TLParser.VarDeclContext vCtx: ctx.varDeclList().varDecl()) {
            String writeVar = vCtx.Identifier().getText();
            String rhs = (vCtx.Number() == null)? "0": vCtx.Number().getText();

            String initValName = "iv" + counter;
            appendVarToBuffer(initValName, result.InitialValue);
            this.result.actionsNumber++;
            appendVarToBuffer(writeVar, result.MemoryLocation);

            result.programBuffer.append("\n /* " + vCtx.getText() + " */ \n");
            result.programBuffer.append("\n and o[" + initValName + "] = p" + currentProcNumber +
                                        "\n and wl[" + initValName + "] = " + writeVar +
                                        "\n and wV[" + initValName + "] = " + rhs + "\n");
            this.counter++;
        }


        return null;
    }

    static String encodeVarName(String originalName) {
        return originalName + "_VAR";
    }

    static String decodeVarName(String encodedName) {
        return encodedName.substring(0, encodedName.lastIndexOf("_VAR"));
    }

    @Override
    public Object visitLocalDecl(TLParser.LocalDeclContext ctx) {
        for (TLParser.VarDeclContext vCtx: ctx.varDeclList().varDecl()) {
            String localVar = vCtx.Identifier().getText();
            String rhs = (vCtx.Number() == null)? null: vCtx.Number().getText();

            appendVarToBuffer(encodeVarName(localVar), result.Integers);

            if (rhs != null) {
                result.programBuffer.append("\n /* " + vCtx.getText() + " */ \n");
                result.programBuffer.append("\n and " + encodeVarName(localVar) + " = " + rhs + "\n");
            }
        }
        return null;
    }

  
    private void appendPOtoProg(String firstActionName, String latestActionName) {
        if (this.lastActionName != null) {
            result.programBuffer.append("\n and " + firstActionName + " in po[" + this.lastActionName + "]\n");
        }
        this.lastActionName = latestActionName;
    }

    private void appendVarToBuffer(String var, StringBuffer buffer) {
        if (buffer.length() > 0) {
            buffer.append(", ");
        }
        buffer.append(var);
    }

    private void condAppend(String var, StringBuffer sb) {
        appendVarToBuffer(var, sb);
    }

    private void condTypePrint(String actionName, String type) {
        result.programBuffer.append("\n and " + actionName + " in " + type);
    }

    public Object visitStore(TLParser.StoreContext ctx) {

        String writeVar = ctx.Identifier().getText();
        String rhs = ctx.rhs().getText();

        String storeName = "lw" + counter;

        result.programBuffer.append("\n /* " + ctx.getText() + " */ \n");

        if (if_context_counter == 0) {

        	condAppend(storeName, result.actionW);
        } else {

            appendVarToBuffer(storeName, result.Items);
            condTypePrint(storeName, "Write");
            actions_in_ifs.peek().add(storeName);
        }

        result.programBuffer.append("\n and o[" + storeName + "] = p" + currentProcNumber +
                "\n and d[" + storeName + "] = p" + currentProcNumber +
                "\n and wl[" + storeName + "] = " + writeVar +
                "\n and wV[" + storeName + "] = " + rhs);

          appendPOtoProg(storeName, storeName);
          this.result.actionsNumber++;
         this.counter++;
 
        return null;
    }

//    public Object visitLoad(TLParser.LoadContext ctx) {
//        String lhs = ctx.Identifier(0).getText();
//        String readVar = ctx.Identifier(1).getText();
//        String readAtomicity = ctx.atomicity().getText();
//        String loadName = "lr" + counter;
//
//        result.programBuffer.append("\n /* " + ctx.getText() + " */ \n");
//        if (if_context_counter == 0) {
//
//            condAppend(readAtomicity.equals("atm"), loadName, result.ARead, result.NRead);
//        } else {
//
//            appendVarToBuffer(loadName, result.Items);
//            condTypePrint(readAtomicity.equals("atm"), loadName, "ARead", "NRead");
//            actions_in_ifs.peek().add(loadName);
//        }
//
//        result.programBuffer.append("\n and o[" + loadName + "] = p" + currentProcNumber +
//                "\n and d[" + loadName + "] = p" + currentProcNumber +
//                "\n and rl[" + loadName + "] = " + readVar +
//                "\n and reg[" + loadName + "] = " + encodeVarName(lhs));
//        appendPOtoProg(loadName, loadName);
//        this.result.actionsNumber++;
//        this.counter++;
//
//        return null;
//    }

//    public Object visitGet(TLParser.GetContext ctx) {
//        int destProcessNumber = Integer.parseInt(ctx.Number().getText());
//        String writeVar = ctx.Identifier(0).getText();
//        String readVar = ctx.Identifier(1).getText();
//        String readName = "vr" + counter;
//        String writeName = "vw" + counter;
//
//        String writeAtomicity = ctx.atomicity(0).getText();
//        String readAtomicity = ctx.atomicity(1).getText();
//
//        result.programBuffer.append("\n /* " + ctx.getText() + " */ \n");
//
//        if (if_context_counter == 0) {
//
//            condAppend(readAtomicity.equals("atm"), readName, result.ARemoteRead, result.NRemoteRead);
//            condAppend(writeAtomicity.equals("atm"), writeName, result.AExternWrite, result.NExternWrite);
//        } else {
//
//            appendVarToBuffer(readName, result.Items);
//            appendVarToBuffer(writeName, result.Items);
//            condTypePrint(readAtomicity.equals("atm"), readName, "ARemoteRead", "NRemoteRead");
//            condTypePrint(writeAtomicity.equals("atm"), writeName, "AExternWrite", "NExternWrite");
//            actions_in_ifs.peek().add(readName);
//            actions_in_ifs.peek().add(writeName);
//        }
//
//        result.programBuffer.append("\n and o[" + readName + "] = p" + currentProcNumber +
//                "\n and d[" + readName + "] = p" + destProcessNumber +
//                "\n and rl[" + readName + "] = " + readVar +
//                "\n and " + readName + " in eactions[" + readName + "]" +
//                "\n and " + writeName + " in eactions[" + readName + "]" +
//                "\n and #eactions[" + readName + "] = 2" +
//                "\n and o[" + writeName + "] = p" + currentProcNumber +
//                "\n and d[" + writeName + "] = p" + currentProcNumber +
//                "\n and wl[" + writeName + "] = " + writeVar +
//                "\n and " + writeName + " in po[" + readName + "]" +
//                "\n and " + writeName + " in co[" + readName + "]" +
//                "\n and wV[" + writeName + "] = rV[" + readName + "]");
//        appendPOtoProg(readName, writeName);
//        this.result.actionsNumber++;
//        this.result.actionsNumber++;
//        this.counter++;
//
//        return null;
//    }
//
//    public Object visitPut(TLParser.PutContext ctx) {
//        int destProcessNumber = Integer.parseInt(ctx.Number().getText());
//        String writeVar = ctx.Identifier(0).getText();
//        String readVar = ctx.Identifier(1).getText();
//        String readName = "vr" + counter;
//        String writeName = "vw" + counter;
//
//        String writeAtomicity = ctx.atomicity(0).getText();
//        String readAtomicity = ctx.atomicity(1).getText();
//
//        result.programBuffer.append("\n /* " + ctx.getText() + " */ \n");
//
//        if (if_context_counter == 0) {
//
//            condAppend(readAtomicity.equals("atm"), readName, result.AExternRead, result.NExternRead);
//            condAppend(writeAtomicity.equals("atm"), writeName, result.ARemoteWrite, result.NRemoteWrite);
//        } else {
//
//            appendVarToBuffer(readName, result.Items);
//            appendVarToBuffer(writeName, result.Items);
//            condTypePrint(readAtomicity.equals("atm"), readName, "AExternRead", "NExternRead");
//            condTypePrint(writeAtomicity.equals("atm"), writeName, "ARemoteWrite", "NRemoteWrite");
//            actions_in_ifs.peek().add(readName);
//            actions_in_ifs.peek().add(writeName);
//        }
//
//        result.programBuffer.append("\n and o[" + readName + "] = p" + currentProcNumber +
//                "\n and d[" + readName + "] = p" + currentProcNumber +
//                "\n and rl[" + readName + "] = " + readVar +
//                "\n and " + readName + " in eactions[" + writeName + "]" +
//                "\n and " + writeName + " in eactions[" + writeName + "]" +
//                "\n and #eactions[" + writeName + "] = 2" +
//                "\n and o[" + writeName + "] = p" + currentProcNumber +
//                "\n and d[" + writeName + "] = p" + destProcessNumber +
//                "\n and wl[" + writeName + "] = " + writeVar +
//                "\n and " + writeName + " in po[" + readName + "]" +
//                "\n and " + writeName + " in co[" + readName + "]" +
//                "\n and wV[" + writeName + "] = rV[" + readName + "]");
//
//        appendPOtoProg(readName, writeName);
//        this.counter++;
//        this.result.actionsNumber++;
//        this.result.actionsNumber++;
//
//        return null;
//    }

//    public Object visitRga(TLParser.RgaContext ctx) {
//        int destProcessNumber = Integer.parseInt(ctx.Number().getText());
//        String writeVar = ctx.Identifier(0).getText();
//        String readWriteVar = ctx.Identifier(1).getText();
//        String readVar = ctx.Identifier(2).getText();
//        String readName = "vr" + counter;
//        String readWriteName = "vrw" + counter;
//        String writeName = "vw" + counter;
//
//        String readAtomicity =  ctx.atomicity(0).getText();
//        String readWriteAtomicity = ctx.atomicity(1).getText();
//        String writeAtomicity = ctx.atomicity(2).getText();
//
//        result.programBuffer.append("\n /* " + ctx.getText() + " */ \n");
//
//        if (if_context_counter == 0) {
//            condAppend(readAtomicity.equals("atm"), readName, result.AExternRead, result.NExternRead);
//            condAppend(readWriteAtomicity.equals("atm"), readWriteName, result.ARemoteReadWrite, result.NRemoteReadWrite);
//            condAppend(writeAtomicity.equals("atm"), writeName, result.AExternWrite, result.NExternWrite);
//        } else {
//
//            appendVarToBuffer(readName, result.Items);
//            appendVarToBuffer(readWriteName, result.Items);
//            appendVarToBuffer(writeName, result.Items);
//            condTypePrint(readAtomicity.equals("atm"), readName, "AExternRead", "NExternRead");
//            condTypePrint(readWriteAtomicity.equals("atm"), readWriteName, "ARemoteReadWrite", "NRemoteReadWrite");
//            condTypePrint(writeAtomicity.equals("atm"), writeName, "AExternWrite", "NExternWrite");
//            actions_in_ifs.peek().add(readName);
//            actions_in_ifs.peek().add(readWriteName);
//            actions_in_ifs.peek().add(writeName);
//        }
//
//        result.programBuffer.append("\n and o[" + readName + "] = p" + currentProcNumber +
//                "\n and d[" + readName + "] = p" + currentProcNumber +
//                "\n and rl[" + readName + "] = " + readVar +
//                "\n and " + readName + " in eactions[" + readWriteName + "]" +
//                "\n and " + readWriteName + " in eactions[" + readWriteName + "]" +
//                "\n and " + writeName + " in eactions[" + readWriteName + "]" +
//                "\n and #eactions[" + readWriteName + "] = 3" +
//
//                "\n and o[" + readWriteName + "] = p" + currentProcNumber +
//                "\n and d[" + readWriteName + "] = p" + destProcessNumber +
//                "\n and wl[" + readWriteName + "] = " + readWriteVar +
//                "\n and " + readWriteName + " in po[" + readName + "]" +
//                "\n and " + readWriteName + " in co[" + readName + "]" +
//                "\n and wV[" + readWriteName + "] = rV[" + readWriteName + "].plus[rV[" + readName + "]]" +
//
//                "\n and o[" + writeName + "] = p" + currentProcNumber +
//                "\n and d[" + writeName + "] = p" + currentProcNumber +
//                "\n and wl[" + writeName + "] = " + writeVar +
//                "\n and wV[" + writeName + "] = rV[" + readWriteName + "]" +
//                "\n and " + writeName + " in po[" + readWriteName + "]" +
//                "\n and " + writeName + " in co[" + readWriteName + "]");
//        
//            /* add hypothesis that RW and W execute atomically, without any act between them */
//        
//        //result.programBuffer.append("\n and (all act: Action| ((not act = " + readWriteName + ") and (not act = " + writeName + ")) implies "
//        //        + "(not (act in co[" + readWriteName + "] and " + writeName + " in co[act] ) ))");
//        
//            /* add hypothesis that RW acts like a flush */
//        
//        //result.programBuffer.append("\n and (all act: ExternalAction| " + readWriteName + " in po[act] implies " + readWriteName + " in co[act])");
//
//        appendPOtoProg(readName, writeName);
//        this.counter++;
//        this.result.actionsNumber+=3;
//
//        return null;
//    }

//    public Object visitCas(TLParser.CasContext ctx) {
//        int destProcessNumber = Integer.parseInt(ctx.Number().getText());
//        String writeVar = ctx.Identifier(0).getText();
//        String swapVar = ctx.Identifier(1).getText();
//        String readCompareVar = ctx.Identifier(2).getText();
//        String readNewVar = ctx.Identifier(3).getText();
//
//        String readCompareName = "vr" + counter + "_1";
//        String readNewName = "vr" + counter + "_2";
//        String swapName = "vrw" + counter + "";
//        String writeName = "vw" + counter;
//
//        String readCompareAtomicity = ctx.atomicity(0).getText();
//        String readNewAtomicity = ctx.atomicity(1).getText();
//        String swapAtomicity = ctx.atomicity(2).getText();
//        String writeAtomicity = ctx.atomicity(3).getText();
//
//        result.programBuffer.append("\n /*" + ctx.getText() + " */ \n");
//
//        if (if_context_counter == 0) {
//            condAppend(readCompareAtomicity.equals("atm"), readCompareName, result.AExternRead, result.NExternRead);
//            condAppend(readNewAtomicity.equals("atm"), readNewName, result.AExternRead, result.NExternRead);
//            condAppend(swapAtomicity.equals("atm"), swapName, result.ARemoteReadWrite, result.NRemoteReadWrite);
//            condAppend(writeAtomicity.equals("atm"), writeName, result.AExternWrite, result.NExternWrite);
//        } else {
//            appendVarToBuffer(readCompareName, result.Items);
//            appendVarToBuffer(readNewName, result.Items);
//            appendVarToBuffer(swapName, result.Items);
//            appendVarToBuffer(writeName, result.Items);
//
//            condTypePrint(readCompareAtomicity.equals("atm"), readCompareName, "AExternRead", "NExternRead");
//            condTypePrint(readNewAtomicity.equals("atm"), readNewName, "AExternRead", "NExternRead");
//            condTypePrint(swapAtomicity.equals("atm"), swapName, "ARemoteReadWrite", "NRemoteReadWrite");
//            condTypePrint(writeAtomicity.equals("atm"), writeName, "AExternWrite", "NExternWrite");
//
//            actions_in_ifs.peek().add(readCompareName);
//            actions_in_ifs.peek().add(readNewName);
//            actions_in_ifs.peek().add(swapName);
//            actions_in_ifs.peek().add(writeName);
//        }
//
//        result.programBuffer.append("\n and o[" + readCompareName + "] = p" + currentProcNumber +
//                    "\n and d[" + readCompareName + "] = p" + currentProcNumber +
//                    "\n and rl[" + readCompareName + "] = " + readCompareVar +
//                    "\n and " + readCompareName + " in eactions[" + swapName + "]" +
//                    "\n and " + readNewName + " in eactions[" + swapName + "]" +
//                    "\n and " + swapName + " in eactions[" + swapName + "]" +
//                    "\n and " + writeName + " in eactions[" + swapName + "]" +
//                    "\n and #eactions[" + swapName + "] = 4" +
//
//                    "\n and o[" + readNewName + "] = p" + currentProcNumber +
//                    "\n and d[" + readNewName + "] = p" + currentProcNumber +
//                    "\n and rl[" + readNewName + "] = " + readNewVar +
//                    "\n and " + readNewName + " in po[" + readCompareName + "]" +
//
//                    "\n and o[" + swapName + "] = p" + currentProcNumber +
//                    "\n and d[" + swapName + "] = p" + destProcessNumber +
//                    "\n and wl[" + swapName + "] = " + swapVar +
//                    "\n and " + swapName + " in po[" + readNewName + "]" +
//                    "\n and " + swapName + " in co[" + readNewName + "]" +
//                    "\n and " + swapName + " in co[" + readCompareName + "]" +
//                    "\n and ((rV[" + swapName + "] = rV[" + readCompareName + "]) implies" +
//                    "\n (wV[" + swapName + "] = rV[" + readNewName + "]) else" +
//                    "\n (wV[" + swapName + "] = rV[" + swapName + "]))" +
//
//                    "\n and o[" + writeName + "] = p" + currentProcNumber +
//                    "\n and d[" + writeName + "] = p" + currentProcNumber +
//                    "\n and wl[" + writeName + "] = " + writeVar +
//                    "\n and wV[" + writeName + "] = rV[" + swapName +"]" +
//                    "\n and " + writeName + " in po[" + swapName + "]" +
//                    "\n and " + writeName + " in co[" + swapName + "]");
//
//        appendPOtoProg(readCompareName, writeName);
//        this.counter++;
//        this.result.actionsNumber+=4;
//
//
//        return null;
//    }

    public Object visitRhs(TLParser.RhsContext ctx) {
        if (ctx.Number() != null) {
            simpleExpressionBuffer.append(ctx.getText());
        } else {
            simpleExpressionBuffer.append(ctx.getText() + ".value");
        }
        return null;
    }

    public Object visitSimpleExpression(TLParser.SimpleExpressionContext ctx) {
        if (ctx.And() != null) {
            /* simpleExpression And simpleExpression*/
            simpleExpressionBuffer.append("(");
            visitSimpleExpression(ctx.simpleExpression(0));
            simpleExpressionBuffer.append(" and ");
            visitSimpleExpression(ctx.simpleExpression(1));
            simpleExpressionBuffer.append(")");

        } else if (ctx.Or() != null) {
            /* simpleExpression Or simpleExpression */
            simpleExpressionBuffer.append("(");
            visitSimpleExpression(ctx.simpleExpression(0));
            simpleExpressionBuffer.append(" or ");
            visitSimpleExpression(ctx.simpleExpression(1));
            simpleExpressionBuffer.append(")");

        } else if (ctx.Excl() != null) {
            /* Excl simpleExpression */
            simpleExpressionBuffer.append("not (");
            visitSimpleExpression(ctx.simpleExpression(0));
            simpleExpressionBuffer.append(")");

        } else if (ctx.OParen() != null) {
            /* OParen simpleExpression CParen */
            simpleExpressionBuffer.append("(");
            visitSimpleExpression(ctx.simpleExpression(0));
            simpleExpressionBuffer.append(")");

        }else if (ctx.Equals() != null) {
            /* Identifier Equals rhs */
            simpleExpressionBuffer.append(encodeVarName(ctx.Identifier().getText()) + ".value = " );
            visitRhs(ctx.rhs());

        } else if (ctx.NEquals() != null) {
            /* Identifier NEquals rhs */
            simpleExpressionBuffer.append("(not (" + encodeVarName(ctx.Identifier().getText()) + ".value = " );
            visitRhs(ctx.rhs());
            simpleExpressionBuffer.append("))");

        } else {
            System.err.println("Error");
            System.exit(1);
        }
        return null;
    }

    public Object visitAssumption(TLParser.AssumptionContext ctx) {
        /* Reset the buffer */
        simpleExpressionBuffer.setLength(0);

        visitSimpleExpression(ctx.simpleExpression());

        /* Append buffer to result */
        result.programBuffer.append("\n /* " + ctx.getText() + " */ \n");
        result.programBuffer.append("\n and " + simpleExpressionBuffer.toString());

        // System.out.println("Assumption found: " + simpleExpressionBuffer.toString());

        return null;
    }

    public Object visitAssertion(TLParser.AssertionContext ctx) {
        /* Reset the buffer */
        simpleExpressionBuffer.setLength(0);

        visitSimpleExpression(ctx.simpleExpression());

        /* Append buffer to result */
        if (result.Assertion.length() > 0) {
            result.Assertion.append(" and " + "(" + simpleExpressionBuffer + ")");
        } else {
            result.Assertion.append("(" + simpleExpressionBuffer + ")");
        }

        // System.out.println("Assertion found: " + result.Assertion.toString());

        return null;
    }



    public Object visitIfStatement(TLParser.IfStatementContext ctx) {
        simpleExpressionBuffer.setLength(0);

        List<String> actions = new ArrayList<String>();
        actions_in_ifs.push(actions);

        /* enter if context */
        this.if_context_counter += 1;

        visitSimpleExpression(ctx.simpleExpression());

        /* append if to result */
        result.programBuffer.append("\n /* if " + simpleExpressionBuffer.toString() + " */ \n");
        result.programBuffer.append("\n and ((" + simpleExpressionBuffer.toString() + ") implies ((1 = 1) ");


        visitBlock(ctx.block());

        result.programBuffer.append("\n) else ((1 = 1) ");

        for (String action : actions) {
            result.programBuffer.append("\n and " + action + " in Item-Action");
        }

        result.programBuffer.append("\n))");

        actions_in_ifs.pop();
        if (!actions_in_ifs.empty()) {
            actions_in_ifs.peek().addAll(actions);
        }


        /* leave if context */
        this.if_context_counter -= 1;
        return null;
    }
}
