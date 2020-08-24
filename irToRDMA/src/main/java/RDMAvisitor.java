// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
import java.util.List;
import java.util.Map;


import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;

public class RDMAvisitor extends TLBaseVisitor<Object> {
    InstanceValue result;
    StringBuilder simpleExpressionBuffer, expressionBuffer;
    
    
    Node currentNode;
    Proc currentProc;
    int counter;

    public RDMAvisitor(InstanceValue result) {
        this.result = result;
        simpleExpressionBuffer = new StringBuilder();
        expressionBuffer = new StringBuilder();
    }

    @Override
    public Object visitNode(TLParser.NodeContext ctx) {
        int nodeNumber = Integer.parseInt(ctx.Number().getText());
        this.currentNode = new Node(nodeNumber);
        result.nodes.add(this.currentNode);
        result.nodeProcesses.put(this.currentNode.nodeNumber, new ArrayList<>());

        visitChildren(ctx);
        return null;
    }
    
    @Override
    public Object visitProcess(TLParser.ProcessContext ctx) {
        int procNumber = Integer.parseInt(ctx.Number().getText());
        this.currentProc = new Proc(procNumber);
        result.processes.add(this.currentProc);
        result.nodeProcesses.get(currentNode.nodeNumber).add(procNumber);
        result.processContents.put(this.currentProc.procId, new ArrayList<>());

        visitChildren(ctx);
        return null;
    }

    @Override
    public Object visitSharedDecl(TLParser.SharedDeclContext ctx) {
        return null;//handled by VarVisitor
    }

    @Override
    public Object visitLocalDecl(TLParser.LocalDeclContext ctx) {
        return null;//handled by VarVisitor
    }

//    @Override
//    public Object visitStatement(TLParser.StatementContext ctx) {
//        visitChildren(ctx);
//        return null;
//    }

    @Override
    public Object visitAssignment(TLParser.AssignmentContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procId);

        String lhs = ctx.Identifier().getText();

        expressionBuffer.setLength(0);
        if (ctx.expression() instanceof TLParser.NumberExpressionContext)
            visitNumberExpression((TLParser.NumberExpressionContext)ctx.expression());
        else {
            System.out.println("unhandled expr in assignment stmt");
            System.exit(1);
        }

        String rhs = expressionBuffer.toString();

        String newInst = String.format("%s = %s;", lhs, rhs);
        insts.add(newInst);

        return null;
    }

    @Override
    public Object visitPollcq(TLParser.PollcqContext ctx) {
        int q = Integer.parseInt(ctx.Number().getText());
        List<String> insts = result.processContents.get(this.currentProc.procId);

        String newInst = String.format("POLL_CQ(con.at(%d),whoami);", q);
        insts.add(newInst);
        return null;
    }

    @Override
    public Object visitStore(TLParser.StoreContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procId);

        String writeVar = ctx.Identifier().getText();
        String rhs = ctx.rhs().getText();

        String newInst = String.format("%s = %s;", writeVar, rhs);
        insts.add(newInst);

        return null;
    }

    @Override
    public Object visitLoad(TLParser.LoadContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procId);

        String lhs = ctx.Identifier(0).getText();
        String readVar = ctx.Identifier(1).getText();

        String newInst = String.format("%s = %s;", lhs, readVar);
        insts.add(newInst);

        return null;
    }

    @Override
    public Object visitGet(TLParser.GetContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procId);

        int destProcessNumber = Integer.parseInt(ctx.Number().getText());
        String writeVar = ctx.Identifier(0).getText();
        String readVar = ctx.Identifier(1).getText();

        String newInst = String.format
	    ("POST_GET(con.at(%d), whoami, %s, %s);", destProcessNumber, readVar, writeVar);
        insts.add(newInst);
        return null;
    }

    @Override
    public Object visitPut(TLParser.PutContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procId);

        int destProcessNumber = Integer.parseInt(ctx.Number().getText());
        String writeVar = ctx.Identifier(0).getText();
        String readVar = ctx.Identifier(1).getText();


        String newInst = String.format
                ("POST_PUT(con.at(%d), whoami, %s, %s);", destProcessNumber, readVar, writeVar);
        insts.add(newInst);
        return null;
    }

    @Override
    public Object visitCas(TLParser.CasContext ctx) {
        List<String> insts = result.processContents.get(this.currentProc.procId);

        int destProcessNumber = Integer.parseInt(ctx.Number(0).getText()),
	        		   cmpVal = Integer.parseInt(ctx.Number(1).getText()),
	        		   wrtVal = Integer.parseInt(ctx.Number(2).getText());
        String writeVar = ctx.Identifier(0).getText();
        String rwVar = ctx.Identifier(1).getText();

        String newInst = String.format
            ("POST_CAS(con.at(%d), whoami, %s,%s,%d,%d);", 
            		destProcessNumber, rwVar, writeVar,cmpVal,wrtVal);
        insts.add(newInst);
        if(! result.atomicVars.containsKey(destProcessNumber)) {
        	result.atomicVars.put(destProcessNumber, new HashSet<>());
        }
        result.atomicVars.get(destProcessNumber).add(rwVar);

        return null;
    }

    @Override
    public Object visitOutput(TLParser.OutputContext ctx) {
        simpleExpressionBuffer.setLength(0);

        visitSimpleExpression(ctx.simpleExpression());

        result.outputs.add(simpleExpressionBuffer.toString());
        return null;
    }

    @Override
    public Object visitRga(TLParser.RgaContext ctx) {
        // W = rga(RW, R)
        List<String> insts = result.processContents.get(this.currentProc.procId);

        int destProcessNumber = Integer.parseInt(ctx.Number(0).getText()),
     		   diffV = Integer.parseInt(ctx.Number(1).getText());
        String writeVar = ctx.Identifier(0).getText();
        String rwVar = ctx.Identifier(1).getText();

        String newInst = String.format
            ("POST_RGA(con.at(%d), whoami, %s,%s,%d);", 
            		destProcessNumber,rwVar,  writeVar, diffV);
        insts.add(newInst);
        if(! result.atomicVars.containsKey(destProcessNumber)) {
        	result.atomicVars.put(destProcessNumber, new HashSet<>());
        }
        result.atomicVars.get(destProcessNumber).add(rwVar);

        return null;
    }
 
    @Override
    public Object visitRhs(TLParser.RhsContext ctx) {
        simpleExpressionBuffer.append(ctx.getText());
        return null;
    }

    @Override
    public Object visitNumberExpression(TLParser.NumberExpressionContext ctx) {
	expressionBuffer.append(ctx.Number());
	return null;
    }

    @Override
    public Object visitSimpleExpression(TLParser.SimpleExpressionContext ctx) {
        if (ctx.And() != null) {
            /* simpleExpression And simpleExpression*/
            simpleExpressionBuffer.append("(");
            visitSimpleExpression(ctx.simpleExpression(0));
            simpleExpressionBuffer.append(" && ");
            visitSimpleExpression(ctx.simpleExpression(1));
            simpleExpressionBuffer.append(")");

        } else if (ctx.Or() != null) {
            /* simpleExpression Or simpleExpression */
            simpleExpressionBuffer.append("(");
            visitSimpleExpression(ctx.simpleExpression(0));
            simpleExpressionBuffer.append(" || ");
            visitSimpleExpression(ctx.simpleExpression(1));
            simpleExpressionBuffer.append(")");

        } else if (ctx.Excl() != null) {
            /* Excl simpleExpression */
            simpleExpressionBuffer.append("! (");
            visitSimpleExpression(ctx.simpleExpression(0));
            simpleExpressionBuffer.append(")");

        } else if (ctx.OParen() != null) {
            /* OParen simpleExpression CParen */
            simpleExpressionBuffer.append("(");
            visitSimpleExpression(ctx.simpleExpression(0));
            simpleExpressionBuffer.append(")");

        }else if (ctx.Equals() != null) {
            /* Identifier Equals rhs */
            simpleExpressionBuffer.append(ctx.Identifier().getText() + " == " );
            visitRhs(ctx.rhs());

        } else if (ctx.NEquals() != null) {
            /* Identifier NEquals rhs */
            simpleExpressionBuffer.append("(" + ctx.Identifier().getText() + " != " );
            visitRhs(ctx.rhs());
            simpleExpressionBuffer.append(")");

        } else {
            System.err.println("Error");
            System.exit(1);
        }
        return null;
    }

    @Override
    public Object visitAssumption(TLParser.AssumptionContext ctx) {
        /* Reset the buffer */
        simpleExpressionBuffer.setLength(0);

        visitSimpleExpression(ctx.simpleExpression());

        // System.out.println("Assumption found: " + simpleExpressionBuffer.toString());

        return null;
    }

    @Override
    public Object visitAssertion(TLParser.AssertionContext ctx) {
        /* Reset the buffer */
        simpleExpressionBuffer.setLength(0);

        visitSimpleExpression(ctx.simpleExpression());

        /* Append buffer to result */
        result.owningProcess.put(ctx.simpleExpression(), currentProc.procId);
        result.assertions.add(ctx.simpleExpression());

        // System.out.println("Assertion found: " + result.Assertion.toString());

        return null;
    }

    @Override
    public Object visitIfStatement(TLParser.IfStatementContext ctx) {
        simpleExpressionBuffer.setLength(0);

        visitSimpleExpression(ctx.simpleExpression());

        return null;
    }
}
