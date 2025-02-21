import express, { Request, Response } from "express"

const router = express.Router();

router.get("/", (req: Request, res: Response) => {
    res.json({
        message: "API IS ROCKING",
    });
});

router.post("/", (req: Request, res: Response) => {
    const data = req.body;
    console.log(data);
    res.json({
        message: data,
    });
});

router.get("/about", (req: Request, res: Response) => {
    res.json({
        message: "This is about page",
    });
});


export { router };