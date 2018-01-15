xquery version "1.0-ml";

declare option xdmp:output "method = html";

declare function local:saveBook(
        $title as xs:string,
        $author as xs:string?,
        $year as xs:string?,
        $price as xs:string?,
        $category as xs:string?
) {

    let $id as xs:string := local:sanitizeInput(xdmp:get-request-field("id"))
    let $book as element(book) :=
        element book {
            attribute category { $category },
            attribute id { $id },
            element title { $title },
            element author { $author },
            element year { $year },
            element price { $price }
        }

    let $uri := '/bookstore/book-' || $id || '.xml'
    let $save := xdmp:document-insert($uri, $book)
    let $_ := xdmp:redirect-response("content-admin.xqy")
    return
        ()
};

declare function local:padString(
        $string as xs:string,
        $length as xs:integer,
        $padLeft as xs:boolean
) as xs:string {
    if (fn:string-length($string) = $length) then (
        $string
    ) else if (fn:string-length($string) < $length) then (
        if ($padLeft) then (
            local:padString(fn:concat("0", $string), $length, $padLeft)
        ) else (
            local:padString(fn:concat($string, "0"), $length, $padLeft)
        )
    ) else (
        fn:substring($string, 1, $length)
    )
};

declare function local:sanitizeInput($chars as xs:string?) {
    fn:replace($chars,"[\]\[<>{}\\();%\+]","")
};

(:***************on post request Sanitize the parameters before sending them off to saveBook :)
    if (xdmp:get-request-method() eq "POST") then (

        if(xdmp:get-request-field("update") = "update") then (
            (:gets data from input fields HERE!:)
            let $title as xs:string? := local:sanitizeInput(xdmp:get-request-field("title"))
            let $log := xdmp:log("Update Title is " || $title)
            let $author as xs:string? := local:sanitizeInput(xdmp:get-request-field("author"))
            let $year as xs:string? := local:sanitizeInput(xdmp:get-request-field("year"))
            let $price as xs:string? := local:sanitizeInput(xdmp:get-request-field("price"))
            let $category as xs:string? := local:sanitizeInput(xdmp:get-request-field("category"))
            return
            local:saveBook($title, $author, $year, $price, $category)
        ) else (
            let $log := xdmp:log("trying to delete*******************************")
            let $id as xs:string := local:sanitizeInput(xdmp:get-request-field("id"))
            let $uri := '/bookstore/book-' || $id || '.xml'
            let $x := xdmp:node-delete(doc($uri))
            let $ref := xdmp:redirect-response("content-admin.xqy")
            return
                ""
            ))
    else(),

xdmp:set-response-content-type("text/html"),
'<!DOCTYPE html>',
<html>
<head>
    <link rel="stylesheet" type="text/css" href="/css/style.css"/>
    <!--<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.min.js"></script>
    -->
</head>
    <body>
        <div class="nav-container">
            <a href="book-list.xqy" class="nav-item">Find a Book</a>
            <a href="add-book.xqy" class="nav-item">Add books to Library</a>
            <a href="content-admin.xqy" class="nav-item">Books Admin Page</a>
        </div>
        <h1 class="mainTitle">Book Admin Page</h1>
        <div class="table-container">
            <div class="table-head-container">
                <div class="table-head-title"><strong>Title</strong></div>
                <div class="table-head"><strong>Author</strong></div>
                <div class="table-head"><strong>Year</strong></div>
                <div class="table-head"><strong>Price</strong></div>
                <div class="table-head"><strong>Category</strong></div>
                <div class="table-head"><strong></strong></div>
            </div>

            {
                let $log := xdmp:log(/book)
                for $book in /book
                return
                            <form action="content-admin.xqy" method="post">
                                <div class="table-data-container">
                                    <div class="table-data-edit-title"><input type="text" name="title" value="{data($book/title)}" /> </div>
                                    <div class="table-data-edit"><input type="text" name="author" value="{$book/author}"/> </div>
                                    <div class="table-data-edit"><input type="text" name="year" value="{data($book/year)}"/></div>
                                    <div class="table-data-edit"><input type="text" name="price" value="{$book/price}"/> </div>
                                    <div class="table-data-select">
                                        <select name="category" id="category">
                                        <option/>
                                        {
                                        for $cat in ('CHILDREN','FICTION','NON-FICTION')
                                        return
                                            element option {if ($cat = $book/@category) then (attribute selected {"selected"}) else(),
                                            attribute value {$cat},$cat}
                                        }
                                        </select>
                                    </div>
                                    <input type="hidden" name="id" value="{data($book/@id)}"/>
                                    <div><input type="submit" name="update" value="update" class="table-data-box"/></div>
                                    <div><input type="submit" name="delete" value="delete" class="table-data-box"/></div>
                                </div>
                            </form>
                            }
                        </div>
                    </body>
                </html>
