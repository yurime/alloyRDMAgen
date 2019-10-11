// -*-  indent-tabs-mode:nil; c-basic-offset:4; -*-
// Deprecated 
import org.antlr.v4.runtime.misc.NotNull;
import org.antlr.v4.runtime.tree.TerminalNode;

/**
 * Created by andrei on 28/8/15.
 * Modified by Yuri 09/2019
 */
public class VarsVisitor extends TLBaseVisitor<VarsValue> {
    InstanceValue dv;
    VarsValue result;

    public VarsVisitor(VarsValue value, InstanceValue dv) {
        this.result = value;
        this.dv = dv;
    }

    @Override
    public VarsValue visitProcess(@NotNull TLParser.ProcessContext ctx) {
//        if (ctx.decl() == null) {return null;}
//
//        VarsValue vars = this.visit(ctx.decl());
//
//        final int procNumber = Integer.parseInt(ctx.Number().toString());
//        Proc proc = dv.processes.stream().filter(p -> p.procNumber == procNumber).findFirst().get();
//
//        for (Var v: vars.localVars) {
//            /* add global variables to verify the results at the end of the execution*/
//            vars.sharedVars.add(new Var(v.name + "_sender"));
//            vars.sharedVars.add(new Var(v.name + "_receiver"));
//            vars.sharedVars.add(new Var(v.name + "_global"));
//        }
//        result.procToShared.put(proc, vars.sharedVars);
//        result.procToLocal.put(proc, vars.localVars);
//
//        // System.out.println(result);
//        return null;
    	throw new RuntimeException("not implemented yet");
    }

    @Override
    public VarsValue visitDecl(@NotNull TLParser.DeclContext ctx) {
        VarsValue dResult = new VarsValue();

        if (ctx.sharedDecl() != null) {
            VarsValue shared = this.visit(ctx.sharedDecl());
            dResult.sharedVars = shared.sharedVars;
        }
        if (ctx.localDecl() != null) {
            VarsValue local = this.visit(ctx.localDecl());
            dResult.localVars = local.localVars;
        }

        return dResult;
    }

    @Override
    public VarsValue visitLocalDecl(@NotNull TLParser.LocalDeclContext ctx) {
        VarsValue ldResult = new VarsValue();
        for (TLParser.VarDeclContext vCtx: ctx.varDeclList().varDecl()) {

            String localVarName = vCtx.Identifier().getText();
            Var localVar = new Var(localVarName);

            ldResult.localVars.add(localVar);
            String rhs = (vCtx.Number() == null)? null: vCtx.Number().getText();
            if (rhs != null) {
                // yes, modify the global
                result.localToRHS.put(localVar, rhs);
            }
	    dv.varNameToIndex.put(localVarName, sharedVarCounter++);
        }
        return ldResult;
    }

    int sharedVarCounter = 3;
    @Override
    public VarsValue visitSharedDecl(@NotNull TLParser.SharedDeclContext ctx) {
        VarsValue sdResult = new VarsValue();

        for (TLParser.VarDeclContext node:ctx.varDeclList().varDecl()) {
	    Var v;
	    if (node.Number() == null) {
		v = new Var(node.Identifier().getText());
	    } else {
		v = new Var(node.Identifier().getText(), Integer.parseInt(node.Number().getText()));
	    }
            sdResult.sharedVars.add(v);
	    dv.varNameToIndex.put(v.name, sharedVarCounter++);
        }
        return sdResult;
    }
}
